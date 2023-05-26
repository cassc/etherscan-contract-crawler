// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

// mock class using ERC20
contract DummyToken is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 100000000 * (10**18);

    constructor(string memory name, string memory symbol) public payable ERC20(name, symbol) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function transferInternal(
        address from,
        address to,
        uint256 value
    ) public {
        _transfer(from, to, value);
    }

    function approveInternal(
        address owner,
        address spender,
        uint256 value
    ) public {
        _approve(owner, spender, value);
    }
}