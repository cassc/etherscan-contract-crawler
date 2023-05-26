//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../expansion/interfaces/IExpansion.sol";
import "./AbstractStorefront.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Expansion storefront that facilitates purchases of chosen tokens on a pack, chosen by purchaser
 * @author Ohimire Labs
 */
contract SimpleExpansionStorefront is AbstractStorefront {
    /**
     * @notice Emitted when simple expansion packs are purchased
     * @param saleId ID of sale
     * @param purchaser Purchase transaction sender
     * @param numPurchases Number of purchases on the pack
     * @param tokenIds Chosen tokenIds purchased on the pack
     */
    event SimpleExpansionPackPurchased(
        uint256 indexed saleId,
        address indexed purchaser,
        uint32 numPurchases,
        uint256[] tokenIds
    );

    /**
     * @notice Initialize instance
     * @param platform Platform address
     * @param minter Minter address
     */
    function initialize(address platform, address minter) external initializer {
        // Initialize parent contracts
        __AbstractStorefront_init__(platform, minter);
    }

    /**
     * @notice Mint free packs
     * @param saleId Sale ID
     * @param nftRecipient Recipient of minted NFTs
     * @param tokenIds Tokens to mint on pack, each token must be part of a unique item in the pack
     * @param numPurchases How many of each token to mint
     */
    function mintFreePacks(
        uint256 saleId,
        address nftRecipient,
        uint256[] calldata tokenIds,
        uint32 numPurchases
    ) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId != 0, "zero packId");

        PurchaserType purchaserType = _getPurchaserType(sale.artist, msg.sender);

        // Validate that the mintFreePacks user is either the artist or the platform
        // and decrement the account's freeMint allocation
        if (purchaserType == PurchaserType.artist) {
            require(numPurchases <= sale.mintAmountArtist, "quantity >");
            _sales[saleId].mintAmountArtist -= numPurchases;
        } else if (purchaserType == PurchaserType.platform) {
            require(numPurchases <= sale.mintAmountPlatform, "quantity >");
            _sales[saleId].mintAmountPlatform -= numPurchases;
        } else {
            revert("!authorized");
        }

        IExpansion(sale.tokenContract).mintSameCombination(sale.packId, tokenIds, numPurchases, nftRecipient);

        emit SimpleExpansionPackPurchased(saleId, msg.sender, numPurchases, tokenIds);
    }

    /**
     * @notice Purchase dynamic blueprint NFTs on an active sale
     * @param saleId Sale ID
     * @param presaleWhitelistedQuantity Whitelisted quantity to pair with address on leaf of merkle tree
     * @param proof Merkle proof for purchaser (if presale and whitelisted)
     * @param nftRecipient Recipient of minted NFTs
     * @param tokenIds Tokens to mint on pack, each token must be part of a unique item in the pack
     * @param numPurchases How many of each token to mint
     */
    function purchaseExpansionPacks(
        uint256 saleId,
        uint32 presaleWhitelistedQuantity,
        bytes32[] calldata proof,
        address nftRecipient,
        uint256[] calldata tokenIds,
        uint32 numPurchases
    ) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId != 0, "zero packId");

        _validatePurchaseTimeAndProcessQuantity(sale, saleId, numPurchases, presaleWhitelistedQuantity, proof);

        _validateAndProcessPurchasePayment(sale, numPurchases);
        _payFeesAndArtist(sale, numPurchases);

        IExpansion(sale.tokenContract).mintSameCombination(sale.packId, tokenIds, numPurchases, nftRecipient);

        emit SimpleExpansionPackPurchased(saleId, msg.sender, numPurchases, tokenIds);
    }
}