// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

contract Events {

    event BuyTickets(
        uint256 indexed lotteryIndex,
        uint256 startNumber,
        uint256 finalNumber,
        address indexed buyer
    );

    event GiftTickets(
        uint256 indexed index,
        uint256 startNumber,
        uint256 finalNumber,
        address indexed buyer,
        address indexed recipient
    );

    event LotteryCreated(
        address owner,
        uint256 indexed lotteryIndex,
        address indexed nftAddress,
        uint256 indexed nftId,
        address sellToken,
        uint256 sellAmount,
        uint256 totalTickets,
        uint256 time
    );

    event ConcludeRound(
        address indexed nftAddress,
        address indexed nftWinner,
        uint256 indexed nftId,
        uint256 luckNumber,
        uint256 lotteryIndex
    );

    event RandomWordsFulfilled(
        uint256 indexed lotteryIndex,
        uint256 indexed luckyNumber
    );

    event RequestRandomNumberForRound(
        uint256 indexed lotteryIndex,
        uint256 indexed requestId,
        bool indexed requested
    );
}