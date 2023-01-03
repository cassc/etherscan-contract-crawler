// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Bank.sol";

abstract contract Purse is Bank {
    function transferFromDeployed(
        address operator,
        address from,
        address to,
        uint id,
        uint amount
    ) external virtual;

    function approveDeployed(
        address operator,
        address spender,
        uint coinId,
        uint amount
    ) external virtual;
}

contract Coin is IERC20 {
    Purse private _bank;
    uint private _coin;

    function id() external view returns (uint) {
        return _coin;
    }

    function name() external view returns (string memory) {
        return _bank.nameOf(_coin);
    }

    function symbol() external view returns (string memory) {
        return _bank.symbolOf(_coin);
    }

    function decimals() external view returns (uint8) {
        return _bank.decimals();
    }

    function totalSupply() external view returns (uint) {
        return _bank.totalSupplyOf(_coin);
    }

    function balanceOf(address account) external view returns (uint) {
        return _bank.balanceOf(account, _coin);
    }

    function allowance(address account, address spender) external view returns (uint) {
        return _bank.allowance(account, spender, _coin);
    }

    function approve(address spender, uint amount) external returns (bool) {
        _bank.approveDeployed(msg.sender, spender, _coin, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint amount) external returns (bool) {
        _bank.transferFromDeployed(msg.sender, msg.sender, to, _coin, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        _bank.transferFromDeployed(msg.sender, from, to, _coin, amount);
        emit Transfer(from, to, amount);
        return true;
    }

    constructor(Purse bank_, uint coin_) {
        _bank = bank_;
        _coin = coin_;
    }
}