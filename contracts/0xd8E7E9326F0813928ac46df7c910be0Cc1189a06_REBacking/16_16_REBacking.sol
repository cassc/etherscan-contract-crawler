// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/UpgradeableBase.sol";
import "./IREBacking.sol";

contract REBacking is UpgradeableBase(1), IREBacking
{
    uint256 public propertyAcquisitionCost;

    //------------------ end of storage

    bool public constant isREBacking = true;

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREBacking(newImplementation).isREBacking());
    }
    
    function setPropertyAcquisitionCost(uint256 amount)
        public
        onlyOwner
    {
        propertyAcquisitionCost = amount;
        emit PropertyAcquisitionCost(amount);
    }
}