//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./interfaces/IStorefront.sol";
import "../expansion/interfaces/IExpansion.sol";
import "./AbstractStorefront.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Expansion storefront that facilitates purchases of randomly dispersed tokens in a RandomItem in a pack,
 *         via a 2 phase purchase process
 * @author Ohimire Labs
 */
contract RandomExpansionStorefront is AbstractStorefront {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /**
     * @notice Data containing information on how to calculate a purchaser's expected gas cost.
     *         Pack purchasers must front the gas cost for the purchase fulfillment sent by AsyncArt.
     * @param operationBaseCompute Upper bound on base gas units consumed by a purchase fulfillment tx
     * @param perPackCompute Upper bound on base gas consumed to purchase a pack
     * @param perItemMintCompute Upper bound on cost to mint each item in a given pack
     * @param baseFeeMultiplier Multiplier on block.basefee used to account for uncertainty in future network state
     * @param baseFeeDenominator Denominator for block.basefee used to account for uncertainty in future network state
     * @param minerTip the tip that Async will specify for all purchase fulfillment transactions
     */
    struct FulfillmentGasConstants {
        uint64 operationBaseCompute;
        uint64 perPackCompute;
        uint32 perItemMintCompute;
        uint16 baseFeeMultiplier;
        uint16 baseFeeDenominator;
        uint64 minerTip;
    }

    /**
     * @notice The number of random expansion purchases made, used to id each purchase
     */
    uint256 public numRandomExpansionPurchases;

    /**
     * @notice Account expected to fulfill purchase requests
     */
    address payable public platformPurchaseFulfiller;

    /**
     * @notice Contract's instance of gas constants
     */
    FulfillmentGasConstants public fulfillmentGasConstants;

    /**
     * @notice Track processed purchases to avoid double spending
     */
    EnumerableSetUpgradeable.UintSet private _processedPurchases;

    /**
     * @notice The number of outstanding purchase requests for an expansion pack (DEPRECATED)
     */
    mapping(uint256 => uint64) private _packIdToOutstandingMintRequests;

    /**
     * @notice The number of outstanding purchase requests for an expansion pack v2
     *         (properly indexed by expansion contract address)
     */
    mapping(address => mapping(uint256 => uint64)) private _packIdToOutstandingMintRequestsV2;

    /**
     * @notice Emitted when a user makes a request to purchase an expansion pack with random distribution strategy
     * @param purchaseId Purchase ID
     * @param saleId ID of sale
     * @param purchaseQuantity How many times a sale is purchased in one process
     * @param requestingPurchaser The initial purchaser
     * @param nftRecipient The recipient to send the randomly minted NFTs to
     * @param isAllocatedForFree The "purchase request" is part of the platform/artist's free allocation
     * @param prefixHash The prefix of the hash used by AsyncArt to determine the random Expanion items to be minted
     * @param gasSurcharge The amount of eth the requestingPurchaser was required to
     *                     front for the fulfillment transaction
     */
    event RandomExpansionPackPurchaseRequest(
        uint256 purchaseId,
        uint256 saleId,
        uint32 purchaseQuantity,
        address requestingPurchaser,
        address nftRecipient,
        bool isAllocatedForFree,
        bytes32 prefixHash,
        uint256 gasSurcharge
    );

    /**
     * @notice Emitted when Async fulfills a request to purchase an expansion pack
     * @param purchaseId Purchase ID
     */
    event PurchaseRequestFulfilled(uint256 purchaseId);

    /**
     * @notice Reverts if caller is not platform fulfiller
     */
    modifier onlyFulfiller() {
        require(msg.sender == platformPurchaseFulfiller, "Not fulfiller");
        _;
    }

    /**
     * @notice Initialize storefront instance
     * @param platform Platform account
     * @param minter Platform minter account
     * @param fulfiller Platform fulfiller account
     * @param _fulfillmentGasConstants Fulfillment gas constants
     */
    function initialize(
        address platform,
        address minter,
        address payable fulfiller,
        FulfillmentGasConstants calldata _fulfillmentGasConstants
    ) external initializer {
        // Initialize parent contracts
        __AbstractStorefront_init__(platform, minter);

        // Initialize state variables
        platformPurchaseFulfiller = fulfiller;
        fulfillmentGasConstants = _fulfillmentGasConstants;
    }

    /**
     * @notice Request a number of free pre-allocated pack mints, used by the artist and platform
     * @param saleId ID of sale
     * @param mintQuantity The number of pack mints which are desired
     * @param nftRecipient Recipient of minted NFTs
     */
    function requestFreeAllocatedPacks(uint256 saleId, uint32 mintQuantity, address nftRecipient) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId != 0, "zero packId");

        PurchaserType purchaserType = _getPurchaserType(sale.artist, msg.sender);

        // Validate that the requestFreeAllocatedPacks caller is either the artist or the platform
        // and decrement the account's free pack allocation
        if (purchaserType == PurchaserType.artist) {
            require(mintQuantity <= sale.mintAmountArtist, "quantity >");
            _sales[saleId].mintAmountArtist -= mintQuantity;

            // validate that the artist provided enough gas to cover async's subsequent fulfilling transaction
            uint256 gasCost = _getGasSurcharge(sale, mintQuantity, block.basefee);
            require(msg.value >= ((gasCost * 9) / 10), "$ < fulfilling gas");
            _transferGasCostToFulfiller(gasCost);
        } else if (purchaserType == PurchaserType.platform) {
            require(mintQuantity <= sale.mintAmountPlatform, "quantity >");
            _sales[saleId].mintAmountPlatform -= mintQuantity;
        } else {
            revert("!authorized");
        }

        uint64 numMintRequests = _packIdToOutstandingMintRequestsV2[sale.tokenContract][sale.packId];
        IExpansion.Pack memory packForSale = IExpansion(sale.tokenContract).getPack(sale.packId);

        // require that this mint request is fulfillable
        require(
            numMintRequests + mintQuantity + packForSale.mintedCount <= packForSale.capacity ||
                packForSale.capacity == 0,
            "cant service req"
        );

        numRandomExpansionPurchases += 1;
        _packIdToOutstandingMintRequestsV2[sale.tokenContract][sale.packId] = numMintRequests + mintQuantity;

        emit RandomExpansionPackPurchaseRequest(
            numRandomExpansionPurchases,
            saleId,
            mintQuantity,
            msg.sender,
            nftRecipient,
            true,
            _getPrefixHash(),
            msg.value
        );
    }

    /**
     * @notice Request a number of purchases on a sale, receving randomly distributed expansion NFTs
     * @param saleId ID of sale
     * @param purchaseQuantity How many times the sale is being purchased in a process
     * @param presaleWhitelistedQuantity Whitelisted quantity to pair with address on leaf of merkle tree
     * @param proof Merkle proof for purchaser (if presale and whitelisted)
     * @param nftRecipient Recipient of minted NFTs
     */
    function requestPurchaseExpansionPacks(
        uint256 saleId,
        uint32 purchaseQuantity,
        uint32 presaleWhitelistedQuantity,
        bytes32[] calldata proof,
        address nftRecipient
    ) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId != 0, "zero packId");

        _validatePurchaseTimeAndProcessQuantity(sale, saleId, purchaseQuantity, presaleWhitelistedQuantity, proof);
        uint64 numMintRequests = _packIdToOutstandingMintRequestsV2[sale.tokenContract][sale.packId];
        IExpansion.Pack memory packForSale = IExpansion(sale.tokenContract).getPack(sale.packId);

        // require that this purchase request is fulfillable
        require(
            numMintRequests + purchaseQuantity + packForSale.mintedCount <= packForSale.capacity ||
                packForSale.capacity == 0,
            "cant service req"
        );

        uint256 gasDeposit = _validateAndProcessPurchasePaymentRandom(sale, purchaseQuantity);

        numRandomExpansionPurchases += 1;
        _packIdToOutstandingMintRequestsV2[sale.tokenContract][sale.packId] = numMintRequests + purchaseQuantity;
        emit RandomExpansionPackPurchaseRequest(
            numRandomExpansionPurchases,
            saleId,
            purchaseQuantity,
            msg.sender,
            nftRecipient,
            false,
            _getPrefixHash(),
            gasDeposit
        );
    }

    /**
     * @notice Execute a purchase request, minting the randomly generated token ids on a pack
     * @param purchaseId Purchase ID
     * @param saleId ID of sale
     * @param nftRecipient Recipient of minted NFTs
     * @param requestingPurchaser The initial purchaser
     * @param tokenIdCombinations The different, unique token id combinations being minted on a pack
     * @param numCombinationPurchases The number of times each unique combination should be minted
     * @param isForFreeAllocation Response to request to mint (part of) artist/platform's free expansion pack allocation
     */
    function executePurchaseExpansionPacks(
        uint256 purchaseId,
        uint256 saleId,
        address nftRecipient,
        address requestingPurchaser,
        uint256[][] calldata tokenIdCombinations,
        uint32[] calldata numCombinationPurchases,
        bool isForFreeAllocation
    ) external payable onlyFulfiller {
        // process purchase
        require(_processedPurchases.add(purchaseId), "Purchase already processed");

        uint32 purchaseQuantity = 0;
        for (uint i = 0; i < numCombinationPurchases.length; i++) {
            purchaseQuantity += numCombinationPurchases[i];
        }

        Sale memory sale = _sales[saleId];
        require(sale.packId != 0, "zero packId"); // reserved for DBP

        if (!isForFreeAllocation) {
            _payFeesAndArtist(sale, purchaseQuantity);
        }

        if (tokenIdCombinations.length == 1) {
            // gas optimization for common case, call lighter-weight method
            IExpansion(sale.tokenContract).mintSameCombination(
                sale.packId,
                tokenIdCombinations[0],
                numCombinationPurchases[0],
                nftRecipient
            );
        } else {
            IExpansion(sale.tokenContract).mintDifferentCombination(
                sale.packId,
                tokenIdCombinations,
                numCombinationPurchases,
                nftRecipient
            );
        }
        // record that the purchase has been fulfilled
        _packIdToOutstandingMintRequestsV2[sale.tokenContract][sale.packId] -= purchaseQuantity;

        // If Async fulfiller provided a gas refund amount, transfer it back to the requesting purchaser
        if (msg.value > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = requestingPurchaser.call{ value: msg.value }("");
            /* solhint-enable avoid-low-level-calls */
            require(success, "gas refund transfer failed");
        }

        emit PurchaseRequestFulfilled(purchaseId);
    }

    /**
     * @notice Admin function to update the gas constants
     * @param newFulfillmentGasConstants New gas constants
     */
    function updateFulfillmentGasConstants(
        FulfillmentGasConstants calldata newFulfillmentGasConstants
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fulfillmentGasConstants = newFulfillmentGasConstants;
    }

    /**
     * @notice Admin function to update the authorized fulifller
     * @param newFulfiller New fulfiller
     */
    function updatePlatformFulfiller(address payable newFulfiller) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformPurchaseFulfiller = newFulfiller;
    }

    /**
     * @notice Used primarily in upgrade to migrate V1 data about outstanding mint requests
     * @dev Initializes all tokenContract - packId pairs that had non-zero outstanding mint requests,
     *      which is the uncommon case.
     * @param tokenContracts List of expansion contracts
     * @param packIds Associated packId for each expansion contract
     * @param outstandingMintRequests Associated number of outstanding mint requests for each expansion pack
     */
    function fillOutstandingMintRequestsV2Data(
        address[] calldata tokenContracts,
        uint256[] calldata packIds,
        uint64[] calldata outstandingMintRequests
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenContractsLength = tokenContracts.length;
        require(tokenContractsLength == packIds.length, "Mismatched length");
        require(tokenContractsLength == outstandingMintRequests.length, "Mismatched length");
        for (uint256 i = 0; i < tokenContractsLength; i++) {
            _packIdToOutstandingMintRequestsV2[tokenContracts[i]][packIds[i]] = outstandingMintRequests[i];
        }
    }

    /**
     * @notice Get the IDs of processed purchases
     */
    function getProcessedPurchases() external view returns (uint256[] memory) {
        return _processedPurchases.values();
    }

    /**
     * @notice Return true if a purchase has been processed
     * @param purchaseId ID of purchase being checked
     */
    function isPurchaseProcessed(uint256 purchaseId) external view returns (bool) {
        return _processedPurchases.contains(purchaseId);
    }

    /**
     * @notice Return the estimated excess gas a random purchase requester should provide in addition to
     *         the purchase price in order to successful submit their purchase request.
     * @param saleId The id of the sale on the pack which the user wants to purchase
     * @param purchaseQuantity The number of packs of the sale that the user wants to purchase
     * @param blockBaseFee The base fee of a recent block to anchor the estimate
     */
    function estimateGasSurcharge(
        uint256 saleId,
        uint256 purchaseQuantity,
        uint256 blockBaseFee
    ) external view returns (uint256) {
        return _getGasSurcharge(_sales[saleId], purchaseQuantity, blockBaseFee);
    }

    /**
     * @notice Return the estimated excess gas a random purchase requester should provide in addition
     *         to the purchase price in order to successful submit their purchase request.
     * @param sale The sale on the pack which the user wants to purchase
     * @param purchaseQuantity The number of packs of the sale that the user wants to purchase
     * @param blockBaseFee The basefee of a reference block
     */
    function _getGasSurcharge(
        Sale memory sale,
        uint256 purchaseQuantity,
        uint256 blockBaseFee
    ) internal view returns (uint256) {
        uint256 numItems = IExpansion(sale.tokenContract).getPack(sale.packId).itemSizes.length;
        FulfillmentGasConstants memory gasConstants = fulfillmentGasConstants;
        uint256 gasUnitEstimate = gasConstants.operationBaseCompute +
            ((gasConstants.perPackCompute + (numItems * gasConstants.perItemMintCompute)) * purchaseQuantity);
        uint256 estimatedFulfillmentBaseFee = (blockBaseFee * gasConstants.baseFeeMultiplier) /
            gasConstants.baseFeeDenominator;
        return (estimatedFulfillmentBaseFee + gasConstants.minerTip) * gasUnitEstimate;
    }

    /**
     * @notice Validate purchase and process payment. Returns the total size of the user's gas deposit.
     * @param sale Sale
     * @param purchaseQuantity How many times the sale is being purchased in a process
     */
    function _validateAndProcessPurchasePaymentRandom(
        Sale memory sale,
        uint32 purchaseQuantity
    ) private returns (uint256) {
        // Compute minimum gasSurcharge given current network state
        uint256 gasSurcharge = _getGasSurcharge(sale, purchaseQuantity, block.basefee);
        uint256 gasDeposit = msg.value;
        // Require valid payment
        if (sale.erc20Token == address(0)) {
            require(msg.value >= purchaseQuantity * sale.price + ((gasSurcharge * 9) / 10), "$ < expected");
            gasDeposit = gasDeposit - (purchaseQuantity * sale.price);
        } else {
            require(msg.value >= ((gasSurcharge * 9) / 10), "gas $ < expected");
            IERC20(sale.erc20Token).transferFrom(msg.sender, address(this), purchaseQuantity * sale.price);
        }
        _transferGasCostToFulfiller(gasDeposit);
        return gasDeposit;
    }

    /**
     * @notice Transfer the gas cost for a purchase fulfillment transaction to the AsyncArt platform purchase fulfiller
     * @param gasCost The amount of ether to transfer to the fulfiller account
     */
    function _transferGasCostToFulfiller(uint256 gasCost) private {
        /* solhint-disable avoid-low-level-calls */
        (bool success, ) = platformPurchaseFulfiller.call{ value: gasCost }("");
        /* solhint-enable avoid-low-level-calls */
        require(success, "fulfiller payment failed");
    }

    /**
     * @notice returns the prefix of the hash used by AsyncArt to determine which random tokens to mint
     */
    function _getPrefixHash() private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.number, block.timestamp, block.coinbase));
    }
}