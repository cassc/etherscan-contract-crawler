// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title   Interface of ERC1155Permit contract
/// @author  Primitive
interface IERC1155Permit is IERC1155 {
    /// ERRORS ///

    /// @notice Thrown when the signature has expired
    error SigExpiredError();

    /// @notice Thrown when the signature is invalid
    error InvalidSigError();

    /// EFFECT FUNCTIONS ///

    /// @notice          Grants or revokes the approval for an operator to transfer any of the owner's
    ///                  tokens using their signature
    /// @param owner     Address of the owner
    /// @param operator  Address of the operator
    /// @param approved  True if the approval should be granted, false if revoked
    /// @param deadline  Expiry of the signature, as a timestamp
    /// @param v         Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r         Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s         Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address owner,
        address operator,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// VIEW FUNCTIONS ///

    /// @notice Returns the current nonce of an address
    /// @param owner Address to inspect
    /// @return Current nonce of an address
    function nonces(address owner) external view returns (uint256);

    /// @notice Returns the domain separator
    /// @return Hash of the domain separator
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}