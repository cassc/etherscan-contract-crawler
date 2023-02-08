// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICurveFactory {
    function getProtocolFee() external view returns (int128);
    function getProtocolTreasury() external view returns (address);
    function getGlobalFrozenState() external view returns (bool);
    function getFlashableState() external view returns (bool);
    function isPoolGuarded(address pool) external view returns (bool);
    function getPoolGuardAmount(address pool) external view returns (uint256);
    function getPoolCap(address pool) external view returns (uint256);
}