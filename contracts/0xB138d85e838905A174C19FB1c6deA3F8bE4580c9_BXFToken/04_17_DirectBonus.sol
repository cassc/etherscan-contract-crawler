// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AccountStorage.sol";


abstract contract DirectBonus is AccountStorage {

    using SafeMath for uint256;

    uint256 private DIRECT_BONUS_FEE = 10;
    uint256 private MINIMUM_SELF_BUY_FOR_DIRECT_BONUS = 0.001 ether;

    bytes32 public constant DIRECT_BONUS_MANAGER_ROLE = keccak256("DIRECT_BONUS_MANAGER_ROLE");

    event MinimumSelfBuyForDirectBonusUpdate(uint256 amount);
    event DirectBonusFeeUpdate(uint256 fee);


    function getDirectBonusFee() public view returns(uint256) {
        return DIRECT_BONUS_FEE;
    }


    function setDirectBonusFee(uint256 fee) public {
        require(hasRole(DIRECT_BONUS_MANAGER_ROLE, msg.sender), "DirectBonus: must have direct bonus manager role to set direct bonus fee");
        DIRECT_BONUS_FEE = fee;

        emit DirectBonusFeeUpdate(fee);
    }


    function getMinimumSelfBuyForDirectBonus() public view returns(uint256) {
        return MINIMUM_SELF_BUY_FOR_DIRECT_BONUS;
    }


    function setMinimumSelfBuyForDirectBonus(uint256 amount) public {
        require(hasRole(DIRECT_BONUS_MANAGER_ROLE, msg.sender), "DirectBonus: must have direct bonus manager role to set minimum self buy for direct bonus");
        MINIMUM_SELF_BUY_FOR_DIRECT_BONUS = amount;

        emit MinimumSelfBuyForDirectBonusUpdate(amount);
    }


    function calculateDirectBonus(uint256 amount) internal view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, DIRECT_BONUS_FEE), 100);
    }


    function isEligibleForDirectBonus(address sponsor) internal view returns(bool) {
        return (selfBuyOf(sponsor) >= MINIMUM_SELF_BUY_FOR_DIRECT_BONUS);
    }
}