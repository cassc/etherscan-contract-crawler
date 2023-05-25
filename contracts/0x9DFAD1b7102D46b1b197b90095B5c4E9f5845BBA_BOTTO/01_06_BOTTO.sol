// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

/// @title Eleven-Yellow BOTTO token
/// @notice Supports standard ERC20 token activity including token burn.
/// @dev Initial supply is specified on creation & minted to deployer. Burning tokens reduces total supply.
contract BOTTO is ERC20Burnable {
    /// @param name_ name of the token
    /// @param symbol_ symbol of the token
    /// @param initialSupply_ token supply, expressed in "wei"
    /// @dev Expects token name, symbol, & initial supply on construction
    /// @dev Initial supply is expected to "have 18 decimals"
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_) {
        _mint(_msgSender(), initialSupply_);
    }
}