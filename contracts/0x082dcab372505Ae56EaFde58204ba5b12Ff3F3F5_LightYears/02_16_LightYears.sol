// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

import "./TokenBase.sol";

contract LightYears is TokenBase {
    constructor(
        string memory name,
        string memory symbol,
        address royaltyReceiver,
        string memory baseURI_
    ) TokenBase(name, symbol, 1, 100, royaltyReceiver) {
        baseURI = baseURI_;
    }

    // MINTER FUNCTIONS

    /// @notice Mint an unclaimed token to the given address
    /// @dev Can only be called by the `minter` address
    /// @param to The new token owner that will receive the minted token
    /// @param tokenId The token being claimed. Reverts if invalid or already claimed.
    function mint(address to, uint256 tokenId) external onlyMinter {
        // CHECKS inputs
        require(tokenId != 0 && tokenId <= 100, "Invalid token ID");
        // CHECKS + EFFECTS (not _safeMint, so no interactions)
        _mint(to, tokenId);
        // More EFFECTS
        unchecked {
            totalSupply++;
        }
    }

    /// @notice Query if a contract implements an interface
    /// @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return
            interfaceId == 0x40c10f19 || // Selector for: mint(address, uint256)
            super.supportsInterface(interfaceId);
    }
}