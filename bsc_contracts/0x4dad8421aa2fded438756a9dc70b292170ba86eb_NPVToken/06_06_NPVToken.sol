// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from  "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from  "@openzeppelin/contracts/access/Ownable.sol";

/// @notice NPV tokens are used to track the net present value of future yield.
contract NPVToken is ERC20, Ownable {

    /// @notice Create an NPVToken.
    /// @param name Name of the token.
    /// @param symbol Symbol of the token.
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable() {
    }

    /// @notice Mint new NPV tokens.
    /// @param recipient Recipient of the new tokens.
    /// @param amount Amount of tokens to mint.
    function mint(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }

    /// @notice Burn NPV tokens.
    /// @param recipient Recipient of the burn.
    /// @param amount Amout of tokens to burn.
    function burn(address recipient, uint256 amount) external onlyOwner {
        require(recipient == msg.sender, "NPVT: can only burn own");
        require(balanceOf(recipient) >= amount, "NPVT: insufficient balance");
        _burn(recipient, amount);
    }
}