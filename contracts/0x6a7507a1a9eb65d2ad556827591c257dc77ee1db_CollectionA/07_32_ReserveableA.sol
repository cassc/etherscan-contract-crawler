// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./RevealableA.sol";

/// @title ReserveableA
/// @author Chain Labs
/// @notice Module that adds functionality of reserving tokens from sale. Reserved tokens cannot be bought.
/// @dev Reserves tokens from token ID 1, mints them on demand
contract ReserveableA is RevealableA {
    //------------------------------------------------------//
    //
    //  Owner only functions
    //
    //------------------------------------------------------//

    /// @notice mint tokens to be reserved
    /// @dev  mint tokens to owner account to be reserved
    /// @param _reserveTokens number of tokens to be reserved
    function reserveTokens(uint256 _reserveTokens) external onlyOwner {
        _setReserveTokens(_reserveTokens);
    }

    /// @notice mint tokens to be reserved
    /// @dev internal method to mint tokens to owner account to be reserved
    /// @param _reserveTokens number of tokens to be reserved
    function _setReserveTokens(uint256 _reserveTokens) internal {
        require(
            _reserveTokens + reservedTokens + presaleReservedTokens <=
                maximumTokens,
            "RS:002"
        );
        if (_reserveTokens > 0) {
            reservedTokens += _reserveTokens;
            _safeMint(owner(), _reserveTokens);
        }
    }
}