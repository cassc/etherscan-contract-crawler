// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for including owned NFT token address and token ID information.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterHolderV0 is IFilteredMinterV0 {
    /**
     * @notice Registered holders of NFTs at address `_NFTAddress` to be
     * considered for minting.
     */
    event RegisteredNFTAddress(address indexed _NFTAddress);

    /**
     * @notice Unregistered holders of NFTs at address `_NFTAddress` to be
     * considered for minting.
     */
    event UnregisteredNFTAddress(address indexed _NFTAddress);

    /**
     * @notice Allow holders of NFTs at addresses `_ownedNFTAddresses`, project
     * IDs `_ownedNFTProjectIds` to mint on project `_projectId`.
     * `_ownedNFTAddresses` assumed to be aligned with `_ownedNFTProjectIds`.
     * e.g. Allows holders of project `_ownedNFTProjectIds[0]` on token
     * contract `_ownedNFTAddresses[0]` to mint.
     */
    event AllowedHoldersOfProjects(
        uint256 indexed _projectId,
        address[] _ownedNFTAddresses,
        uint256[] _ownedNFTProjectIds
    );

    /**
     * @notice Remove holders of NFTs at addresses `_ownedNFTAddresses`,
     * project IDs `_ownedNFTProjectIds` to mint on project `_projectId`.
     * `_ownedNFTAddresses` assumed to be aligned with `_ownedNFTProjectIds`.
     * e.g. Removes holders of project `_ownedNFTProjectIds[0]` on token
     * contract `_ownedNFTAddresses[0]` from mint allowlist.
     */
    event RemovedHoldersOfProjects(
        uint256 indexed _projectId,
        address[] _ownedNFTAddresses,
        uint256[] _ownedNFTProjectIds
    );

    // Triggers a purchase of a token from the desired project, to the
    // TX-sending address, using owned ERC-721 NFT to claim right to purchase.
    function purchase(
        uint256 _projectId,
        address _ownedNftAddress,
        uint256 _ownedNftTokenId
    ) external payable returns (uint256 tokenId);

    // Triggers a purchase of a token from the desired project, to the specified
    // receiving address, using owned ERC-721 NFT to claim right to purchase.
    function purchaseTo(
        address _to,
        uint256 _projectId,
        address _ownedNftAddress,
        uint256 _ownedNftTokenId
    ) external payable returns (uint256 tokenId);
}