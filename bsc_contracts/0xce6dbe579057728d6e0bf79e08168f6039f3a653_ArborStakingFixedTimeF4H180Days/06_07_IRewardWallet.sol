//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRewardWallet {
    function deposit(address staker, uint256 amount) external ;
    function transfer(address account, uint256 amount) external ;
}