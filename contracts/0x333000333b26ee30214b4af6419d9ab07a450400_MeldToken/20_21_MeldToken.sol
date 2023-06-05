// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./BaseToken.sol";

/// @author MELD team
/// @title MeldToken
/// @notice MeldToken is an ERC20 token with minting, burning and pausing capabilities, as well as meta-transaction support.
contract MeldToken is BaseToken {
    /// @dev The maximum supply of MELD tokens is 4 billion
    uint256 public constant MAX_SUPPLY = 4_000_000_000 * 10 ** 18;

    constructor(address _defaultAdmin) BaseToken(_defaultAdmin, "Meld", "MELD", 18) {
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /// @notice Mints MELD tokens to an account
    /// @dev Only callable by an account with MINTER_ROLE
    /// @dev The amount of MELD tokens minted in a minting period cannot exceed the minting amount threshold
    /// @dev The MELD token has a maximum supply of 4 billion
    /// @param _to The account to mint MELD tokens to
    /// @param _amount The amount of MELD tokens to mint
    function mint(address _to, uint256 _amount) public override {
        require(totalSupply() + _amount <= MAX_SUPPLY, "MeldToken: Max supply reached");
        super.mint(_to, _amount);
    }
}