//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @notice Based on the reference implementation of the EIP-4494
/// @notice See https://github.com/dievardump/erc721-with-permits and https://eips.ethereum.org/EIPS/eip-4494
/// @author Simon Fremaux (@dievardump) & William SchwabSchwab (@wschwab)
interface IERC4494 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Allows to retrieve current nonce for token
    /// @param tokenId token id
    /// @return current token nonce
    function nonces(uint256 tokenId) external view returns (uint256);

    /// @notice function to be called by anyone to approve `spender` using a Permit signature
    /// @dev Anyone can call this to approve `spender`, even a third-party
    /// @param spender the actor to approve
    /// @param tokenId the token id
    /// @param deadline the deadline for the permit to be used
    /// @param signature permit
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;
}