// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// @title Interface of next contract
// @dev should be able to mint previous token staked on previous contract with `migrateTokens`
interface INextContract {
    function receiveTokens(
        uint256[] calldata _tokenIds,
        address[] calldata _owners
    ) external;
}