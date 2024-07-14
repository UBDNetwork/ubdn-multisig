// SPDX-License-Identifier: MIT
// UBD Network DeTrustModel_01_Executive
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ContextUpgradeable, Initializable} from "@Uopenzeppelin/contracts/utils/ContextUpgradeable.sol";

/**
 * @dev This is a  trust model implementation that can execute any encoded transactions.
 * Upon creation the address of the heir(s) and the timestamp (X)
 *  are passed. When the heir  applies, this X will be checked. If now is 
 * greater than X, then both the creator and the heir have access 
 * to the wallet's assets. 
 * 
 * !!! This is implementation contract for proxy conatract creation
 */
contract DeTrustMultisigModel_02 is 
    Initializable, 
    ContextUpgradeable 
{
    
    struct Fee {
        uint256 feeAmount;
        address feeToken;
        uint64  payedTill;
        address feeBeneficiary;
    }
    /// @custom:storage-location erc7201:ubdn.storage.DeTrustModel_01_Executive
    struct DeTrustModelStorage_02 {
        address creator;
        uint64 inheritedDate;
        string name;
        Fee fee;
        bytes32[] inheritorHashes;
    }

    uint64 public constant ANNUAL_FEE_PERIOD = 365 days;

    // keccak256(abi.encode(uint256(keccak256("ubdn.storage.DeTrustModel_02_Executive")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant DeTrustModelStorageLocation =  0x21ab7451c00b7fa4356bfcd83c8c178a19d008a84997997eff634b52cb7deb00;    
    
    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);
    
    event EtherTransfer(uint256 amount);

    /**
     * @dev Throws if called by any account other than the creator 
     *  or inheritor after silence time.
     */
    modifier onlyCreatorOrInheritor() {
        _checkCreatorOrInheritor();
        _;
    }

    // constructor() {
    //   _disableInitializers();
    // }

    function initialize(
        address _creator,
        bytes32[] calldata _inheritorHashes,
        uint64  _inheritDate,
        string memory _name,
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary
    ) public initializer
    {
        __DeTrustModel_02_Executive_init(
            _creator, _inheritorHashes, _inheritDate, _name, 
            _feeToken, _feeAmount, _feeBeneficiary
        );

    }

    /**
     * @dev Sets the sender as the initial owner, the beneficiary as the pending owner, 
     * the start timestamp and the
     * vesting duration of the vesting wallet.
     */
    function __DeTrustModel_02_Executive_init(
        address _creator,
        bytes32[] calldata _inheritorHashes,
        uint64  _inheritDate,
        string memory _name,
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary
    ) internal onlyInitializing 
    {
        //__Ownable_init_unchained(_owner);
        __DeTrustModel_02_Executive_init_unchained(
            _creator, _inheritorHashes, _inheritDate, _name, 
            _feeToken, _feeAmount, _feeBeneficiary
        );
    }

    function __DeTrustModel_02_Executive_init_unchained(
        address _creator,
        bytes32[] calldata _inheritorHashes,
        uint64  _inheritDate,
        string memory _name,
        address _feeToken,
        uint256 _feeAmount,
        address _feeBeneficiary
    ) internal onlyInitializing 
    {
        require(_inheritorHashes.length <=100, "Too much inheritors");
        DeTrustModelStorage_02 storage $ = _getDeTrustModel_02_ExecutiveStorage();
        $.inheritedDate = _inheritDate;
        $.creator = _creator;
        $.name = _name;
        $.fee.feeToken = _feeToken;
        $.fee.feeAmount = _feeAmount;
        $.fee.feeBeneficiary = _feeBeneficiary;
        $.fee.payedTill = uint64(block.timestamp) + ANNUAL_FEE_PERIOD;
        for (uint8 i; i < _inheritorHashes.length; ++ i) {
            $.inheritorHashes.push(_inheritorHashes[i]);
        }
    }


    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {
        emit EtherTransfer(msg.value);
    }

    /**
     * @dev Use this method for acces native token balance
     * @param _to address of receiver
     * @param _value value in wei
     */
    function transferNative(address _to, uint256 _value) 
        external
        onlyCreatorOrInheritor 
    {
        DeTrustModelStorage_02 storage $ = _getDeTrustModel_02_ExecutiveStorage();
        _chargeFee($, 0);
        Address.sendValue(payable(_to), _value);
        //_updateLastOwnerOp($);
        //$.lastOwnerOp = block.timestamp;
        emit EtherTransfer(_value);
    }

    /**
     * @dev Use this method for acces ERC20 token balance
     * @param _token address of ERC20 asset
     * @param _to address of receiver
     * @param _amount value in wei
     */
    function transferERC20(address _token, address _to, uint256 _amount) 
        external 
        onlyCreatorOrInheritor
    {
       DeTrustModelStorage_02 storage $ = _getDeTrustModel_02_ExecutiveStorage();
       _chargeFee($, 0);
       SafeERC20.safeTransfer(IERC20(_token), _to, _amount);
       //$.lastOwnerOp = block.timestamp;
       //_updateLastOwnerOp($);
    }

    /**
     * @dev Call this method for initiate fee charging
     */
    function iAmAlive() external onlyCreatorOrInheritor {
       DeTrustModelStorage_02 storage $ = _getDeTrustModel_02_ExecutiveStorage();
       _chargeFee($, 0);
       //_updateLastOwnerOp($);
    }

    /**
     * @dev Use this method for interact any dApps onchain
     * @param _target address of dApp smart contract
     * @param _value amount of native token in tx(msg.value)
     * @param _data ABI encoded transaction payload
     */
    function executeOp(
        address _target,
        uint256 _value,
        bytes memory _data
    ) external onlyCreatorOrInheritor returns (bytes memory r) {
        require(_target != address(this), "No Trust itself");
        DeTrustModelStorage_02 storage $ = _getDeTrustModel_02_ExecutiveStorage();
        _chargeFee($, 0);
        //_updateLastOwnerOp($);
        r = Address.functionCallWithValue(_target, _data, _value);
    }

    /**
     * @dev Use this method for interact any dApps onchain, executing as one batch
     * @param _targetArray addressed of dApp smart contract
     * @param _valueArray amount of native token in every tx(msg.value)
     * @param _dataArray ABI encoded transaction payloads
     */
    function executeMultiOp(
        address[] calldata _targetArray,
        uint256[] calldata _valueArray,
        bytes[] memory _dataArray
    ) external onlyCreatorOrInheritor returns (bytes[] memory r) {
        DeTrustModelStorage_02 storage $ = _getDeTrustModel_02_ExecutiveStorage();
        _chargeFee($, 0);
        //_updateLastOwnerOp($);
        r = new bytes[](_dataArray.length);
        for (uint256 i = 0; i < _dataArray.length; ++ i){
            require(_targetArray[i] != address(this), "No Trust itself");
            r[i] = Address.functionCallWithValue(_targetArray[i], _dataArray[i], _valueArray[i]);
        }
    }


    /**
     * @dev Use this method for pay in advance any periods. Available only 
     * for trust owner or inheritor
     * @param _numberOfPeriods to pay fee in advance
     */
    function payFeeAdvance(uint64 _numberOfPeriods) external onlyCreatorOrInheritor {
        DeTrustModelStorage_02 storage $ = _getDeTrustModel_02_ExecutiveStorage();
        _chargeFee($, _numberOfPeriods);
    }

    /**
     * @dev Use this method for for charge fee debt if exist. Available for 
     * any address, for example platform owner
     */
    function chargeAnnualFee() external {
        DeTrustModelStorage_02 storage $ = _getDeTrustModel_02_ExecutiveStorage();
        _chargeFee($, 0);
    }

    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev Use this method for static call any dApps onchain
     * @param _target address of dApp smart contract
     * @param _data ABI encoded transaction payload
     */
    function staticCallOp(
        address _target,
        bytes memory _data
    ) external view onlyCreatorOrInheritor returns (bytes memory r) {
        r = Address.functionStaticCall(_target, _data);
    }

    /**
     * @dev Returns creator of DeTrust proxy
     */
    function creator() external view returns(address){
        DeTrustModelStorage_02 storage $ = _getDeTrustModel_02_ExecutiveStorage();
        return $.creator;
    }

    /**
     * @dev Returns full DeTrust info
     */
    function trustInfo_02() external pure returns(DeTrustModelStorage_02 memory trust){
        trust = _getDeTrustModel_02_ExecutiveStorage();
    }

    /**
     * @dev Returns true during payed period
     */
    function isAnnualFeePayed() external view returns(bool isPayed){
        DeTrustModelStorage_02 storage $ = _getDeTrustModel_02_ExecutiveStorage();
        isPayed = $.fee.payedTill >= uint64(block.timestamp); 
    }

    ////////////////////////////////////////////////////////////////////////

    /**
     * @dev Refresh last operation timestamp
     */
    // function _updateLastOwnerOp(DeTrustModelStorage_02 storage st) internal {
    //     if (_isInList(st)) {
    //         // if code here hence time condition are OK 
    //         // and from this moment assete are inherited
    //         st.inherited = true;
    //     }

    //     if (! st.inherited) {
    //         // update only till inhereted moment
    //         st.lastOwnerOp = block.timestamp;
    //     }

    // }

    function _chargeFee(
        DeTrustModelStorage_02 storage st, 
        uint64 _numberOfPeriods
    ) internal 
    {
        if (_numberOfPeriods == 0) {
            _numberOfPeriods = _feeDebtPeriodsNumber(
                st.fee.payedTill - ANNUAL_FEE_PERIOD, // LAST PAYED DATE
                uint64(block.timestamp)               // Now
            );
        }
        if (st.fee.feeAmount > 0 && _numberOfPeriods > 0){
            if (st.fee.feeToken != address(0)){
                SafeERC20.safeTransfer(
                    IERC20(st.fee.feeToken),
                    st.fee.feeBeneficiary, 
                    st.fee.feeAmount * _numberOfPeriods
                );
            } else {
                address payable s = payable(st.fee.feeBeneficiary);
                s.transfer(st.fee.feeAmount  * _numberOfPeriods);
            }
            st.fee.payedTill += ANNUAL_FEE_PERIOD * _numberOfPeriods;
        }
    }

    function _feeDebtPeriodsNumber(uint64 _lastPayedDate, uint64 _debtDate) 
        internal 
        pure
        returns(uint64 number)
    {
        if (_lastPayedDate  < _debtDate) {
            number = (_debtDate - _lastPayedDate) / ANNUAL_FEE_PERIOD;
        }
    }

    /**
     * @dev Throws if the sender is not the owner
     *  or inheritor after silence time.
     */
    function _checkCreatorOrInheritor() internal view virtual {
        DeTrustModelStorage_02 storage $ = _getDeTrustModel_02_ExecutiveStorage();
        bool isInInheritorList = _isInList($);
         if (
                ($.creator != _msgSender()) && !isInInheritorList
                ||
            (
                  isInInheritorList && (block.timestamp < $.inheritedDate)
            )
        )
        {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function _isInList(DeTrustModelStorage_02 storage st) internal view 
        returns(bool r)
    {
        for (uint256 i = 0; i < st.inheritorHashes.length; ++ i) {
            if (st.inheritorHashes[i] == keccak256(abi.encode(_msgSender()))) {
                r = true;
                break;
            }
        }
    }

    function _getDeTrustModel_02_ExecutiveStorage() 
        private pure returns (DeTrustModelStorage_02 storage $) 
    {
        assembly {
            $.slot := DeTrustModelStorageLocation
        }
    }
}
