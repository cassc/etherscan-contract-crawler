// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "../interfaces/ISignatureVerifier.sol";
import "../external/interfaces/IArtBlocks.sol";

import { IV_NoAmount, IV_ItemMissingAddress, IV_InvalidProjectId } from "../errors/Lending.sol";

/**
 * @title ArtBlocksVerifier
 * @author Non-Fungible Technologies, Inc.
 *
 * See ItemsVerifier for a more thorough description of the Verifier
 * pattern used in Arcade.xyz's lending protocol. This contract
 * verifies predicates that check ownership of a certain ArtBlocks collection
 * by an asset vault, as specified by project ID. For ArtBlocks, many collections
 * live on the same contract, so this allows a counterparty to place "collection"
 * offers not across the whole contract, but for items within that contract.
 *
 * For the ArtBlocks verifier, any verified item is assumed to be ERC721, since
 * all ArtBlocks collections are ERC721.
 *
 * The following ArtBlocks contracts are supported:
 *  - 0x059edd72cd353df5106d2b9cc5ab83a52287ac3a (Day 0 - Squiggles, Genesis, Construction Token)
 *  - 0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270 (ArtBlocks Curated, ArtBlocks Playground, ArtBlocks Factory)
 *
 * The new generation ArtBlocks contract is NOT supported:
 *  - 0x942bc2d3e7a589fe5bd4a5c6ef9727dfd82f5c8a (Explorations)
 *  - 0x99a9b7c1116f9ceeb1652de04d5969cce509b069 (Artblocks GenArt721CoreV3)
 *
 * New generation ArtBlocks contracts are not supported because token ownership is not
 * enumerable.
 */
contract ArtBlocksVerifier is ISignatureVerifier {
    /// @dev Struct describing each item that should be validated
    struct SignatureItem {
        // The address of the collateral contract
        address asset;
        // The artblocks project ID of the collateral. Required input -
        // if one wants a wildcard across ALL projects, can use the
        // standard ItemsVerifier.
        uint256 projectId;
        // The within-project token ID of the collateral, _not_ the on-chain
        // token ID. Ignored if anyIdAllowed is true.
        uint256 tokenId;
        // The minimum amount of collateral. Pass 1 or the
        // amount of assets needed to be held for a wildcard predicate. If the
        // tokenId is specified, the amount is assumed to be 1.
        uint256 amount;
        // Whether any token ID should be allowed. Supersedes tokenId.
        bool anyIdAllowed;
    }

    // Project IDs are multiplied by 1 million to generate an on-chain token ID
    // that encodes the project.
    uint256 public constant PROJECT_ID_BASE = 1_000_000;

    // ==================================== COLLATERAL VERIFICATION =====================================

    /**
     * @notice Verify that the items specified by the packed SignatureItem array are held by the vault.
     * @dev    Reverts on a malformed SignatureItem, returns false on missing contents.
     *
     *         Verification for empty predicates array has been addressed in initializeLoanWithItems and
     *         rolloverLoanWithItems.
     *
     * @param predicates                    The SignatureItem[] array of items, packed in bytes.
     * @param vault                         The vault that should own the specified items.
     *
     * @return verified                     Whether the bundle contains the specified items.
     */
    // solhint-disable-next-line code-complexity
    function verifyPredicates(bytes calldata predicates, address vault) external view override returns (bool) {
        // Unpack items
        SignatureItem[] memory items = abi.decode(predicates, (SignatureItem[]));

        for (uint256 i = 0; i < items.length; ++i) {
            SignatureItem memory item = items[i];

            // No asset provided
            if (item.asset == address(0)) revert IV_ItemMissingAddress();

            uint256 nextProjectId = IArtBlocks(item.asset).nextProjectId();
            if (item.projectId >= nextProjectId) revert IV_InvalidProjectId(item.projectId, nextProjectId);

            // No amount provided
            if (item.amount == 0) revert IV_NoAmount(item.asset, item.amount);

            if (item.anyIdAllowed) {
                // Iterate through tokens
                uint256 tokenCount = IArtBlocks(item.asset).balanceOf(vault);
                uint256 found;

                for (uint256 j = 0; j < tokenCount; j++) {
                    uint256 fullTokenId = IArtBlocks(item.asset).tokenOfOwnerByIndex(vault, j);
                    uint256 ownedProjectId = fullTokenId / PROJECT_ID_BASE;

                    // If project is owned, increment num found
                    // If we've found enough, break
                    if (ownedProjectId == item.projectId) {
                        found++;

                        if (found >= item.amount) break;
                    }
                }

                // We looped and didn't find enough, so fail
                if (found < item.amount) return false;
            } else {
                // Look for a specific token ID
                uint256 fullTokenId = _getFullTokenId(item.projectId, item.tokenId);

                // Check if the token is owned by the vault
                if (IERC721(item.asset).ownerOf(fullTokenId) != vault) {
                    return false;
                }
            }

        }

        // Loop completed - all items found
        return true;
    }

    function _getFullTokenId(uint256 projectId, uint256 tokenId) internal pure returns (uint256) {
        return projectId * PROJECT_ID_BASE + tokenId;
    }
}