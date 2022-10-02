// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.9;
pragma abicoder v2;

interface INFTKEYMarketplaceRoyalty {
    struct ERC721CollectionRoyalty {
        address recipient;
        uint256 feeFraction;
        address setBy;
    }

    // Who can set: ERC721 owner and NFTKEY owner
    event SetRoyalty(
        address indexed erc721Address,
        address indexed recipient,
        uint256 feeFraction
    );

    /**
     * @dev Royalty fee
     * @param erc721Address to read royalty
     * @return royalty information
     */
    function royalty(address erc721Address)
        external
        view
        returns (ERC721CollectionRoyalty memory);

    /**
     * @dev Royalty fee
     * @param erc721Address to read royalty
     */
    function setRoyalty(
        address erc721Address,
        address recipient,
        uint256 feeFraction
    ) external;
}