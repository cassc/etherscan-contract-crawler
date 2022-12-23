// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IDealer {
    function sendToken(address _token, address _to, uint256 _amount) external;
}