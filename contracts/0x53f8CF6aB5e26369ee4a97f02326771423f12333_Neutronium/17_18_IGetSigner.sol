// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Interface for signature verifier contract
 * @notice This interface is used for verifying signatures that are
 * used in ERC20 tokens and NFT operations
 */
interface IGetSigner {
    /**
     * @dev Main function to verify, that address has appropriate role
     * @param to Address to mint
     * @param amount Amount of tokens
     * @param nonce Custom nonce for signature
     * @param deadline Deadline of signature activation period
     * @param signature Signature to check
     * @return Status Status of role ownership
     */
    function verify(
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external view returns (bool);

    /**
     * @dev Same as `verify()`, but for NFT
     * @param to Address to mint
     * @param tokenId Id of NFT
     * @param signature Signature to check
     * @param deadline Deadline of signature activation period
     * @return Status Status of role ownership
     */
    function verifyNft(
        address to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external view returns (bool);

    /**
     * @dev Same as `verify()`, but for other operations
     * @param to Address to mint
     * @param tokenIds Ids of NFT
     * @param signature Signature to check
     * @param opcode Code of operation
     * @param deadline Deadline of signature activation period
     * @return Status Status of role ownership
     */
    function verifyOperation(
        address to,
        uint256[] calldata tokenIds,
        uint256 opcode,
        uint256 deadline,
        bytes memory signature
    ) external view returns (bool);
}