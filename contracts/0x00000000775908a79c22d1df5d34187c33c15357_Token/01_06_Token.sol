// SPDX-License-Identifier: UNLICENSED
// UPGRD is a community driven platform where users can build, collaborate, invest in projects and earn together.
// This ERC20 contract is the utility token used on the UPGRD platform.
// Author: UPGRD Labs
// Year: 2023
// Website: https://upgrd.dev
// Telegram: https://t.me/UPGRD_PORTAL
// Twitter: https://x.com/upgrd_dev

pragma solidity ^0.8.19;

// External contracts
// We use solady highly gas efficient ERC20 implementation
import "solady/src/tokens/ERC20.sol";

// Internal contracts
import "./utils/MEVGuard.sol";
import "./utils/Managed.sol";

contract Token is Managed, MEVGuard, ERC20 {
    constructor(
        address owner_,
        uint256 totalSupply_
    ) {
        _initializeOwner(owner_);
        _mint(owner_, totalSupply_ * (10 ** decimals()));
    }
    
    /// @dev Returns the name of the token.
    function name() public pure override returns (string memory)
    {
        return "UPGRD";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public pure override returns (string memory)
    {
        return "UPGRD";
    }

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (MEV_GUARD_ENABLED) checkCooldown(from);
    }

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (MEV_GUARD_ENABLED) updateCooldown(from);
    }
}