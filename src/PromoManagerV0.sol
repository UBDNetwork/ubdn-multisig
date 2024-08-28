// SPDX-Licence-Identifier: MIT
// UBDN PromoManager V0
pragma solidity 0.8.26;

import "./interfaces/IPromoCodeManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This is a  simple custodian promo Code Manager.
 * Support two types: public and personal promo codes
 */
contract PromoManager is Ownable, IPromoCodeManager {

    struct PromoPeriod {
        uint256 validTill;
        uint64 promoPeriod;
    }

    mapping(bytes32 promo => PromoPeriod period) public promoCodes; 
    mapping(bytes32 promo => mapping(address creator => PromoPeriod period)) public promoCodesPersonal; 

    constructor ()
        Ownable(msg.sender)
    {}

     /**
     * @dev Set promo period for exact user (Personal promo code)
     * @param _promoHash `keccak256` hash of promo code.
     * @param _period structured value for promo period and it`s validity time
     */
    function setPromoPeriod(
        bytes32  _promoHash, 
        PromoPeriod calldata _period
    ) external onlyOwner {
        promoCodes[_promoHash] = _period;
    }

    /**
     * @dev Set promo period for exact user (Personal promo code)
     * @param _promoHash `keccak256` hash of promo code.
     * @param _period structured value for promo period and it`s validity time
     * @param _user address of user for personal promo
     */
    function setPromoPeriodForExactUser(
        bytes32  _promoHash, 
        PromoPeriod calldata _period, 
        address _user
    ) external onlyOwner {
        promoCodesPersonal[_promoHash][_user] = _period;
    }

    /**
     * @dev Returns defined promo period. Personal promo
     * code has priority.
     * @param _impl address of detrust model. Not used in this version
     * @param _creator address of user for personal promo
     * @param _promoHash `keccak256` hash of promo code.
     */
    function getPrepaidPeriod(address _impl, address _creator, bytes32 _promoHash) 
        external
        view
        returns(uint64 prePaidPeriod_)
    {
        // suppress solc warnings, reserved for other versions
        _impl;
        PromoPeriod memory p = promoCodesPersonal[_promoHash][_creator]; 
        prePaidPeriod_ = p.promoPeriod;
        if (p.validTill < block.timestamp) {
            p = promoCodes[_promoHash];
            if (p.validTill >= block.timestamp) {
                prePaidPeriod_ = p.promoPeriod;
            }
        }
    }

    function hlpGetPromoHash(string memory _promo) public pure returns(bytes32) {
        return keccak256(abi.encode(_promo));
    }
}