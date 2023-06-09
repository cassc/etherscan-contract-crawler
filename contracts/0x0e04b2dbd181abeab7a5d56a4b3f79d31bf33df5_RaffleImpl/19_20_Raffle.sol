// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface Raffle {
    event WinnerChosen(address indexed player, uint256 indexed sum, uint256 indexed tokenId);
    event Requested(address indexed player, uint256 requestId);
    event ReffererPaid(uint256 timestamp, address indexed refferer, address refferal, uint256 price, uint256 reward);

    function openRaffle() external;
    function stopRaffle() external;
    function pay(address target, uint256 amountInUsdt) external;
    function sendEther(address target, uint256 amount) external;
    function enterRaffle(address refferer) external payable;
}