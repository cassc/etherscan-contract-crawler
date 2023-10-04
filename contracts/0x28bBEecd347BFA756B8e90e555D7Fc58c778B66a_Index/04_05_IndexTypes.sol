// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

library IndexTypes {
    struct Player {
        address id;
        uint256 avatar;
        address affiliate;
        string username;
    }

    struct Bet {
        uint256 globalId;
        uint256 playerId;
        bytes32 requestId;
        uint256 gameId;
        address player;
        uint256 rolls;
        uint256 bet;
        uint256[50] data;
        uint256 stake;
        uint256 payout;
        bool complete;
        uint256 opened;
        uint256 closed;
    }

    struct PlayerComplex {
        address id;
        string username;
        uint256 avatar;
        uint256 vip;
        uint256 level;
        uint256 xp;
        uint256 playerBets;
        uint256 playerWagers;
        uint256 playerProfits;
        uint256 playerWins;
        uint256 playerLosses;
        uint256 balance;
    }
}