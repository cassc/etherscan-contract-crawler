// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Used for tests.
 */
contract MockToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, 1_000_000);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}