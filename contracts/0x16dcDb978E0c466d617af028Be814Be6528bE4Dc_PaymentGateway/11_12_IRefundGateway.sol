// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRefundGateway {
    function transfer(address _erc20, address _receiver, uint256 _amount) external;
}