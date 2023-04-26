// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './enums/TokenType.sol';

interface ILottery {
    function purchaseTickets(
        address userAddress,
        TokenType tokenType,
        uint256 count
    ) external payable;

    function noteCollection(
        TokenType tokenType,
        uint256 takenLotteryFee
    ) external;

    function withdrawFixedReward(
        uint256 week,
        address userAddress,
        uint8 rank,
        TokenType tokenType
    ) external;

    function claimLotteryAdminRewards(
        uint256 week,
        TokenType tokenType
    ) external;
}