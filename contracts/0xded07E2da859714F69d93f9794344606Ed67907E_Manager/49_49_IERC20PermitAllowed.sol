// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title   Interface for permit
/// @notice  Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
    /// @notice         Approve the spender to spend some tokens via the holder signature
    /// @dev            This is the permit interface used by DAI and CHAI
    /// @param holder   Address of the token holder, the token owner
    /// @param spender  Address of the token spender
    /// @param nonce    Holder's nonce, increases at each call to permit
    /// @param expiry   Timestamp at which the permit is no longer valid
    /// @param allowed  Boolean that sets approval amount, true for type(uint256).max and false for 0
    /// @param v        Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r        Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s        Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}