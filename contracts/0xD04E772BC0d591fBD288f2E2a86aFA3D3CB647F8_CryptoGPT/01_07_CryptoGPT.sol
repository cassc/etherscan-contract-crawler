// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./BaseERC20.sol";

contract CryptoGPT is BaseERC20 {
    constructor(
        address initialOwner,
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) BaseERC20(initialOwner, name, symbol, initialSupply) {}
}