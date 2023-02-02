// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBombSender {
    function sendBomb(address _to, uint256 _amount) external;
}