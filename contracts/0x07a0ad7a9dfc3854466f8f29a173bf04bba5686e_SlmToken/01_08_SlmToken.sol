// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

import "./LockableToken.sol";

/// @title Solomon Token
/// @author Solomon DeFi
/// @notice Solomon ERC20 token (SLM)
contract SlmToken is LockableToken {
	
	constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }

    /// @notice Creates `amount` new tokens for `to`.
    /// @dev See {ERC20-_mint}.
    /// @param to The address that will receive tokens
    /// @param amount The number of tokens to mint
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
	
}