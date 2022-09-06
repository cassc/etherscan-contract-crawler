// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract TestERC20 is ERC20Upgradeable {
    function __TestERC20_init(string memory name_, string memory symbol_)
        external
        initializer
    {
        __ERC20_init(name_, symbol_);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}