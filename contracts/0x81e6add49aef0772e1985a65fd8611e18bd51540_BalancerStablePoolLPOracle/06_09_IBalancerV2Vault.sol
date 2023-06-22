//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBalancerV2Vault {
    function getPoolTokens(
        bytes32 poolId
    )
        external
        view
        returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
}