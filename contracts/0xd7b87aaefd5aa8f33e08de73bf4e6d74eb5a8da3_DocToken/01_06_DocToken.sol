// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title DocToken ERC20 contract
contract DocToken is ERC20, ERC20Burnable {
    /// @notice Contract constructor which initializes on ERC20 core implementation and mints 42.1 billion tokens to deployer
    constructor() ERC20("DocToken", "DOC") {
        _mint(msg.sender, 42100000000 * 10**decimals());
    }
}