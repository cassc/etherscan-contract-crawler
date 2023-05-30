// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface ILL420Wallet {
    function deposit(address _user, uint256 _amount) external;

    function withdraw(address _user, uint256 _amount) external;

    function balance(address _user) external view returns (uint256);
}