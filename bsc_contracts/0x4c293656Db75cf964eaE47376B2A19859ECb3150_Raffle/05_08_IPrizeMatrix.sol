// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IPrizeMatrix{
    enum PrizeType {
        DIRECT,
        OFFLINE,
        PENDING
    }

    struct PrizeLevel {
        uint32 nWinners;
        uint256 prize;
        bool directPayment;
    }

    function getPrizeMatrix(uint32 raffleId) external returns (PrizeLevel[] memory);
}