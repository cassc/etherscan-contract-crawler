// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// mock class using ERC20
contract Zumer is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        address initialAccount,
        uint256 initialBalance
    ) payable ERC20(name, symbol) {
        _mint(initialAccount, initialBalance);
    }
}