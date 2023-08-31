// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IHarvestableApyFlowVault {
    function harvest() external returns (uint256 assets);
}