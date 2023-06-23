//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./AbstractStorefront.sol";
import "../blueprints/interfaces/IDynamicBlueprint.sol";

/**
 * @notice DBP storefront that facilitates purchases of DBP NFTs
 * @author Ohimire Labs
 */
contract SimpleDBPStorefront is AbstractStorefront {
    /**
     * @notice Emitted when DBPs are purchased
     * @param saleId ID of sale
     * @param purchaser Purchase transaction sender
     * @param quantity Amount purchased / minted
     */
    event DBPPurchased(uint256 indexed saleId, address indexed purchaser, uint32 quantity);

    /**
     * @notice Initiliaze the instance
     * @param platform Platform address
     * @param minter Minter address
     */
    function initialize(address platform, address minter) external initializer {
        // Initialize parent contracts
        __AbstractStorefront_init__(platform, minter);
    }

    /**
     * @notice Complimentary minting available in limited quantity to AsyncArt/DBP artists depending on config params
     * @param saleId Sale ID for the DBP
     * @param mintQuantity Number of NFTs to mint (should be within pre-configured limits)
     * @param nftRecipient Recipient of minted NFTs
     */
    function freeMint(uint256 saleId, uint32 mintQuantity, address nftRecipient) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId == 0, "non-zero packId");

        PurchaserType purchaserType = _getPurchaserType(sale.artist, msg.sender);

        // Validate that the freeMint user is either the artist or the platform
        // and decrement the account's freeMint allocation
        if (purchaserType == PurchaserType.artist) {
            require(mintQuantity <= sale.mintAmountArtist, "quantity >");
            _sales[saleId].mintAmountArtist -= mintQuantity;
        } else if (purchaserType == PurchaserType.platform) {
            require(mintQuantity <= sale.mintAmountPlatform, "quantity >");
            _sales[saleId].mintAmountPlatform -= mintQuantity;
        } else {
            revert("!authorized");
        }

        IDynamicBlueprint(sale.tokenContract).mintBlueprints(mintQuantity, nftRecipient);

        emit DBPPurchased(saleId, msg.sender, mintQuantity);
    }

    /**
     * @notice Purchase dynamic blueprint NFTs on an active sale
     * @param saleId Sale ID
     * @param purchaseQuantity How many times the sale is being purchased in this transaction
     * @param presaleWhitelistedQuantity Whitelisted quantity to pair with address on leaf of merkle tree
     * @param proof Merkle proof for purchaser (if presale and whitelisted)
     * @param nftRecipient Recipient of minted NFTs
     */
    function purchaseDynamicBlueprints(
        uint256 saleId,
        uint32 purchaseQuantity,
        uint32 presaleWhitelistedQuantity,
        bytes32[] calldata proof,
        address nftRecipient
    ) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId == 0, "non-zero packId");

        _validatePurchaseTimeAndProcessQuantity(sale, saleId, purchaseQuantity, presaleWhitelistedQuantity, proof);

        _validateAndProcessPurchasePayment(sale, purchaseQuantity);
        _payFeesAndArtist(sale, purchaseQuantity);

        IDynamicBlueprint(sale.tokenContract).mintBlueprints(purchaseQuantity, nftRecipient);

        emit DBPPurchased(saleId, msg.sender, presaleWhitelistedQuantity);
    }
}