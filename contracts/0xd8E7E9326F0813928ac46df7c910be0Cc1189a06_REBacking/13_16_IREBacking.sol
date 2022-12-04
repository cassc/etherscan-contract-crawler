// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";

interface IREBacking is IUpgradeableBase
{
    event PropertyAcquisitionCost(uint256 newAmount);

    function isREBacking() external view returns (bool);
    function propertyAcquisitionCost() external view returns (uint256);
    
    function setPropertyAcquisitionCost(uint256 amount) external;
}