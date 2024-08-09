// SPDX-Licence-Identifier: MIT
// MOck
pragma solidity 0.8.26;

import "../interfaces/IPromoCodeManager.sol";

contract MockPromoManager is IPromoCodeManager {

    function getPrepaidPeriod(address _impl, address _creator, bytes32 _promoHash) 
        external
        pure
        returns(uint64 prePaidPeriod_)
    {
        _impl; 
        _creator;
        _promoHash;
        prePaidPeriod_ = uint64(100 days);
    }
 


}