// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ITicket {
    function mint(uint256 _lotteryId, address _participant) external;
}