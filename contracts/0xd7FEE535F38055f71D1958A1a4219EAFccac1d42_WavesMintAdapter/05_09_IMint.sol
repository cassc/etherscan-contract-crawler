// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMint {
    function mintTokens(
        uint16 executionChainId_,
        string calldata token_,
        uint256 amount_,
        string calldata recipient_,
        uint256 gaslessClaimReward_,
        string calldata referrer_,
        uint256 referrerFee_
    ) external;
}