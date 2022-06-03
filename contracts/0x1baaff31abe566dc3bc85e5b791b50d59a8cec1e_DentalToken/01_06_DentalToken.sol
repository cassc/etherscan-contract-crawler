// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title DentalToken ERC20 contract
contract DentalToken is ERC20, ERC20Burnable {
    /// @notice Contract constructor which initializes on ERC20 core implementation and mints 32.1 billion tokens to deployer
    constructor() ERC20("DentalToken", "SMILE") {
        _mint(msg.sender, 32100000000 * 10**decimals());
    }
}