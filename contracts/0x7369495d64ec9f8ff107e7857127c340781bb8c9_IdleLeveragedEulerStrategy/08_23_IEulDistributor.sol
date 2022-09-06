// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.10;

interface IEulDistributor {
    /// @notice Claim distributed tokens
    /// @param account Address that should receive tokens
    /// @param token Address of token being claimed (ie EUL)
    /// @param proof Merkle proof that validates this claim
    /// @param stake If non-zero, then the address of a token to auto-stake to, instead of claiming
    function claim(
        address account,
        address token,
        uint256 claimable,
        bytes32[] calldata proof,
        address stake
    ) external;
}