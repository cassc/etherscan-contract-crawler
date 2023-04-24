// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMYCStakingFactory {
    function treasury() external view returns (address);

    function signer() external view returns (address);

    function mycStakingManager() external view returns (address);

    function owner() external view returns (address);
}