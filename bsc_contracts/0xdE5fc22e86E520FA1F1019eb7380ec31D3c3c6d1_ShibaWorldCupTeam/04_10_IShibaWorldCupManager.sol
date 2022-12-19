// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShibaWorldCupManager {
    function SWC() external view returns (address);

    function isTradingEnabled() external view returns (bool);

    function sellFee() external view returns (uint256);

    function isExcluded(address account) external view returns (bool);
}