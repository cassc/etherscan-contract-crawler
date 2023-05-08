// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMYCStakingManager {
    function addStakingPool(address poolAddress, bytes32 signature) external;

    function treasury() external view returns (address);

    function signer() external view returns (address);

    function owner() external view returns (address);
}