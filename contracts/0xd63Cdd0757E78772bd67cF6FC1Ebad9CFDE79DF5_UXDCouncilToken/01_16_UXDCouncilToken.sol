// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title UXDCouncilToken
/// @notice UXD governance council token
contract UXDCouncilToken is Ownable, ERC20, ERC20Permit, ERC20Votes {

    constructor(address guardian) ERC20("UXD Council Token", "UXDCouncil") ERC20Permit("UXDCouncil") {
        mint(guardian, 1 * 10 ** decimals());
    }

    /// @notice Mint a new council token
    /// @param to The address to mint to
    /// @param amount The amount to mint
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @notice  Burn a council token
    /// @dev Burns a council token from the caller's address. Balance of msg.sender must be >= amount.
    /// @param amount The amount to burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @notice burn a council token from a specified address
    /// @dev Can only be called by governance. Balance of holder must be >= amount
    /// @param holder The account to burn from
    /// @param amount The amount to burn
    function burnFrom(address holder, uint256 amount) external onlyOwner {
        _burn(holder, amount);
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}