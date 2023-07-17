// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Handles nonces mapping. Required for EIP712-based signatures
abstract contract Nonces {
    /// mapping between the user and the nonce of the account
    mapping(address => uint256) internal _nonces;

    /// @notice Nonce for permit / meta-transactions
    /// @param owner Token owner's address
    /// @return nonce nonce of the owner
    function nonces(address owner) external view returns (uint256 nonce) {
        return _nonces[owner];
    }
}