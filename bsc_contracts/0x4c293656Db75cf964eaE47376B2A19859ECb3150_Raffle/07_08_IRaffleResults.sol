// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IRaffleResults {
    struct RaffleResults {
        uint32 raffleId;
        uint timestamp;
        PrizeLevelWinners[] winnersMatrix;
    }

    struct PrizeLevelWinners {
        address payable [] winners;
    }

    function getRaffleResults(uint32 raffleId) external returns (RaffleResults memory);
}