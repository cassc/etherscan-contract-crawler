// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC20 } from '../dependencies/openzeppelin/contracts/ERC20.sol';

contract ERC20Mock is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        address initialAccount,
        uint256 initialBalance
    ) payable ERC20(_name, _symbol) {
        _mint(initialAccount, initialBalance);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function transferInternal(address from, address to, uint256 value) public {
        _transfer(from, to, value);
    }

    function approveInternal(address owner, address spender, uint256 value) public {
        _approve(owner, spender, value);
    }
}