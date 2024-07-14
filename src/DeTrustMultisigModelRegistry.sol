// SPDX-License-Identifier: MIT
// UBD Network

pragma solidity 0.8.26;

import "./interfaces/IDeTrustModelRegistry.sol";
import "./interfaces/IPromoCodeManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This is model registry for UBD DeTrust ecosystem. Contract 
 * keeps available model's addressee and validate proxy (DeTrusts)
 * creation rules
 */
contract DeTrustMultisigModelRegistry is IDeTrustModelRegistry, Ownable {
     using SafeERC20 for IERC20;
    /**
     * @dev Store information about TrustModel
     */
    struct TrustModel {
        bytes1 rules;         // see from row 52 
        address token;        // ERC20 address for balance check 
        uint256 tokenBalance; // min balance for deTrust creation
        address feeToken;     // Service fee Token
        uint256 feeAmount;    // Service fee amount
    }

    address public immutable feeBeneficiary;
    mapping(address => TrustModel) public approvedModels;
    address[] public modelsList;
    address public promoCodeManager;

    event ModelChanged(address Model);
    event ModelRemoved(address Model);

    constructor(address _feeBeneficiary)
      Ownable(msg.sender)
    {
        require(_feeBeneficiary != address(0),"Please provide fee beneficiary");
        feeBeneficiary = _feeBeneficiary;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}


    /**
     * @dev Returns `true` if Fee charged
     */
    function chargeFee(address _impl, address _creator, bytes32 _promoHash)
        external
        payable
    returns (
        address feeToken_, 
        uint256 feeAmount_, 
        address feeBeneficiary_, 
        uint64 prePaiedPeriod_
    ) 
    {
        TrustModel memory m = approvedModels[_impl];
        feeToken_ = m.feeToken;
        feeAmount_ = m.feeAmount;
        feeBeneficiary_ = feeBeneficiary;
        // Cahrge first fee from trust creator
        if (feeAmount_ > 0){
            if (feeToken_ != address(0)){
                IERC20(feeToken_).safeTransferFrom(_creator, feeBeneficiary, feeAmount_);
            } else {
                // this is implicit check for enough ether in tx
                // becouse starting from 0.8.0 Solidity  overflow control exist
                uint256 diff = msg.value - feeAmount_;
                address payable s = payable(feeBeneficiary);
                s.transfer(feeAmount_);
                if(diff > 0) {
                    s = payable(_creator);
                    s.transfer(diff);
                }
            }
        }
        if (promoCodeManager != address(0)) {
            prePaiedPeriod_ = IPromoCodeManager(promoCodeManager).getPrepaidPeriod(
                _impl,
                _creator,
                _promoHash
            );
        }
    }

    /**
     * @dev Return model rules as byte.
     *
     * Returns one byte array:
     *  7    6    5    4    3    2   1   0  <= Bit number(dec)
     *  ------------------------------------------------------
     *  128  64   32   16   8    4   2   1  <= Bit weight(dec) 
     *  |    |    |    |    |    |   |   |   
     *  |    |    |    |    |    |   |   +-Is_Enabled
     *  |    |    |    |    |    |   +-Need_Balance 
     *  |    |    |    |    |    +-Need_Create_Fee_Charge
     *  |    |    |    |    +-reserved_core
     *  |    |    |    +-reserved_core
     *  |    |    +-reserved_core
     *  |    +-reserved_core  
     *  +-reserved_core
     */
    function isModelEnable(address _impl, address _creator) 
        external 
        view 
        returns (bytes1 _rules) {
        require(_impl != address(0) && _creator != address(0), "No Zero models");    
        _rules = approvedModels[_impl].rules;
    }

    /**
     * @dev Returns `true` or revert with reason.
     */
    function checkRules(address _impl, address _creator)
        external
        view
        returns (bool _ok) 
    {
        TrustModel  memory _m = approvedModels[_impl]; 
        require(
            IERC20(_m.token).balanceOf(_creator) >= _m.tokenBalance,
            "Too low Balance"
        );
        _ok = true;

    }

    /**
     * @dev Returns array of model's addresses
     */
    function getModelsList() external view returns (address[] memory){
        return modelsList;
    } 

   

     /////////////////////////
    ///  Admin functions  ///
    /////////////////////////

    /**
     * @dev Add new model implementation address in registry
     * @param _model model implementation address
     * @param _modelRules structured info about model (see above in TrustModel definition)
     */
    function setModelState(address _model, TrustModel calldata _modelRules) external onlyOwner {
        if (_modelRules.tokenBalance > 0) {
            require(_modelRules.rules & 0x02 == 0x02, "Please enable check balance");
        }
 
        // add new  model to registry
        if (approvedModels[_model].rules == 0x00) {
            modelsList.push(_model);
        } 
        approvedModels[_model] = _modelRules;
        
        emit ModelChanged(_model);
    }

    /**
     * @dev Remove model implementation 
     * @param _model model implementation address
     */
    function removeModel(address _model) external onlyOwner {
        delete approvedModels[_model];
        for (uint256 i = 0; i < modelsList.length; ++ i) {
            if (modelsList[i] == _model) {
                if (i != modelsList.length - 1) {
                    // not last element
                    modelsList[i] = modelsList[modelsList.length - 1];
                }
                modelsList.pop();
                emit ModelRemoved(_model);
            }
        }

    }

    function setPromoCodeManager(address _contract) external onlyOwner {
        promoCodeManager = _contract;
    }
}