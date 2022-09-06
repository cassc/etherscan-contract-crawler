// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRelayerRegistry {
    function stakeToRelayer(address relayer, uint256 stake) external;

    function getRelayerBalance(address relayer) external view returns (uint256);
}