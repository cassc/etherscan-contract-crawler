// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISeaDropToken } from "./ISeaDropToken.sol";

import { PublicDrop } from "../lib/ERC1155SeaDropStructs.sol";

/**
 * @dev A helper interface to get and set parameters for ERC1155SeaDrop.
 *      The token does not expose these methods as part of its external
 *      interface to optimize contract size, but does implement them.
 */
interface IERC1155SeaDrop is ISeaDropToken {
    /**
     * @notice Update the SeaDrop public drop parameters at a given index.
     *
     * @param publicDrop The new public drop parameters.
     * @param index      The public drop index.
     */
    function updatePublicDrop(
        PublicDrop calldata publicDrop,
        uint256 index
    ) external;

    /**
     * @notice Returns the public drop stage parameters at a given index.
     *
     * @param index The index of the public drop stage.
     */
    function getPublicDrop(
        uint256 index
    ) external view returns (PublicDrop memory);

    /**
     * @notice Returns the public drop indexes.
     */
    function getPublicDropIndexes() external view returns (uint256[] memory);

    /**
     * @notice Returns a set of mint stats for the address.
     *         This assists SeaDrop in enforcing maxSupply,
     *         maxTotalMintableByWallet, maxTotalMintableByWalletPerToken,
     *         and maxTokenSupplyForStage checks.
     *
     * @dev    NOTE: Implementing contracts should always update these numbers
     *         before transferring any tokens with _safeMint() to mitigate
     *         consequences of malicious onERC1155Received() hooks.
     *
     * @param minter  The minter address.
     * @param tokenId The token id to return stats for.
     */
    function getMintStats(
        address minter,
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 minterNumMinted,
            uint256 minterNumMintedForTokenId,
            uint256 totalMintedForTokenId,
            uint256 maxSupply
        );

    /**
     * @notice This function is only allowed to be called by the configurer
     *         contract as a way to batch mints and configuration in one tx.
     *
     * @param recipient The address to receive the mints.
     * @param tokenIds  The tokenIds to mint.
     * @param amounts   The amounts to mint.
     */
    function multiConfigureMint(
        address recipient,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;
}