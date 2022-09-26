// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IMamoruNft {
    // NFT sale phase
    enum SalePhase {
        // initial phase is locked
        LOCKED,
        PRE_SALE,
        PUBLIC_SALE
    }

    /**
     * @dev Emitted when new `max supply` is set.
     */
    event MaxSupplySet(uint256 maxSupply);

    /**
     * @dev Emitted when new `maxMintsPerAddress` is set.
     */
    event MaxMintsPerAddressSet(uint256 maxMintsPerAddress);

    /**
     * @dev Emitted when new `maxMintsPerTx` is set.
     */
    event MaxMintsPerTxSet(uint256 maxMintsPerTx);

    /**
     * @dev Emitted when new `publicSaleStartAt` is set.
     */
    event PublicSaleStartTimeSet(uint256 publicSaleStartAt);

    /**
     * @dev Emitted when new `preSalePrice` is set.
     */
    event PreSalePriceSet(uint256 preSalePrice);

    /**
     * @dev Emitted when new `publicSalePrice` is set.
     */
    event PublicSalePriceSet(uint256 publicSalePrice);

    /**
     * @dev Emitted when user mint a token.
     */
    event Mint(address indexed sender, uint256 tokenId);

    /**
     * @dev Emitted when new `baseURI` is set.
     */
    event BaseURISet(string newBaseURI);

    /**
     * @dev Emitted when new `whitelist merkle root` is set.
     */
    event WhitelistMerkleRootSet(bytes32 newWhitelistMerkleRoot);

    /**
     * @dev Emitted when enter new `sale phase`.
     */
    event EnterPhase(SalePhase newSalePhase);

    /**
     * @dev Emitted when withdraw.
     */
    event Withdraw(address indexed sender, uint256 amount);
}