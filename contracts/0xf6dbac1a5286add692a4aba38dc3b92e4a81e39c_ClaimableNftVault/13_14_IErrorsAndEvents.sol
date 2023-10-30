// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IErrorsAndEvents {
    /**
     * @dev Revert with an error when the claim key does not exist.
     */
    error InvalidClaimKey();

    /**
     * @dev Revert with an error when the claim proof is invalid.
     */
    error InvalidClaimProof();

    /**
     * @dev Revert with an error when the caller submits a zero claim amount.
     */
    error InvalidClaimAmount();

    /**
     * @dev Revert with an error when the caller is not the claim admin.
     */
    error InvalidClaimAdmin();

    /**
     * @dev Revert with an error when the caller attempts to claim more than once.
     */
    error CallerHasAlreadyClaimed();

    /**
     * @dev Revert with an error when there isn't enough remaining balance in the vault.
     */
    error InsufficientSupply();

    event ClaimableVaultAssetDeposited(
        address indexed claimAdmin,
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenSupply,
        bytes32 merkleRoot
    );

    event ClaimableVaultAssetDepleted(address indexed claimAdmin, address tokenAddress, uint256 tokenId);

    event ClaimableVaultAssetClaimed(
        address indexed claimAdmin,
        address tokenAddress,
        uint256 tokenId,
        address claimer,
        uint256 amount
    );

    event ClaimableVaultAssetMerkleRootUpdated(
        address indexed claimAdmin,
        address tokenAddress,
        uint256 tokenId,
        bytes32 merkleRoot
    );
}