//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/**
 * @notice Dynamic Blueprint and Expansion storefront interface
 * @author Ohimire Labs
 */
interface IStorefront {
    /**
     * @notice Denotes statate of sale
     */
    enum SaleState {
        not_started,
        started,
        paused
    }

    /**
     * @notice Sale data
     * @param maxPurchaseAmount Max number of purchases allowed in one tx on this sale
     * @param saleEndTimestamp Marks end of sale
     * @param price Price of each purchase of sale
     * @param packId ID of pack that sale is for (if for expansion pack). O if sale is for DBP
     * @param erc20Token Address of erc20 currency that payments must be made in. 0 address if in native gas token
     * @param merkleroot Root of merkle tree containing allowlist
     * @param saleState State of sale
     * @param tokenContract Address of contract where tokens to be minted in sale are
     * @param artist Sale artist
     * @param primaryFee Fee split on sales
     * @param mintAmountArtist How many purchases the artist can mint for free
     * @param mintAmountPlatform How many purchases the platform can mint for free
     */
    struct Sale {
        uint64 maxPurchaseAmount;
        uint128 saleEndTimestamp;
        uint128 price;
        uint256 packId;
        address erc20Token;
        bytes32 merkleroot;
        SaleState saleState;
        address tokenContract;
        address artist;
        PrimaryFeeInfo primaryFee;
        uint256 mintAmountArtist;
        uint256 mintAmountPlatform;
    }

    /**
     * @notice Object holding primary fee data
     * @param feeBPS Primary fee percentage allocations in basis points,
     *               should always add up to 10,000 and include the creator to payout
     * @param feeRecipients Primary fee recipients, including the artist/creator
     */
    struct PrimaryFeeInfo {
        uint32[] feeBPS;
        address[] feeRecipients;
    }

    /**
     * @notice Emitted when a new sale is created
     * @param saleId the ID of the sale which was just created
     * @param packId the ID of the pack which will be sold in the created sale
     * @param tokenContract the ID of the DBP/Expansion contract where the pack on sale was created
     */
    event SaleCreated(uint256 indexed saleId, uint256 indexed packId, address indexed tokenContract);

    /**
     * @notice Emitted when a sale is started
     * @param saleId ID of sale
     */
    event SaleStarted(uint256 indexed saleId);

    /**
     * @notice Emitted when a sale is paused
     * @param saleId ID of sale
     */
    event SalePaused(uint256 indexed saleId);

    /**
     * @notice Emitted when a sale is unpaused
     * @param saleId ID of sale
     */
    event SaleUnpaused(uint256 indexed saleId);

    /**
     * @notice Create a sale
     * @param sale Sale being created
     */
    function createSale(Sale calldata sale) external;

    /**
     * @notice Update a sale
     * @param saleId ID of sale being updated
     * @param maxPurchaseAmount New max purchase amount
     * @param saleEndTimestamp New sale end timestamp
     * @param price New price
     * @param erc20Token New ERC20 token
     * @param merkleroot New merkleroot
     * @param primaryFee New primaryFee
     * @param mintAmountArtist New mintAmountArtist
     * @param mintAmountPlatform New mintAmountPlatform
     */
    function updateSale(
        uint256 saleId,
        uint64 maxPurchaseAmount,
        uint128 saleEndTimestamp,
        uint128 price,
        address erc20Token,
        bytes32 merkleroot,
        PrimaryFeeInfo calldata primaryFee,
        uint256 mintAmountArtist,
        uint256 mintAmountPlatform
    ) external;

    /**
     * @notice Update a sale's state
     * @param saleId ID of sale that's being updated
     * @param saleState New sale state
     */
    function updateSaleState(uint256 saleId, SaleState saleState) external;

    /**
     * @notice Withdraw credits of native gas token that failed to send
     * @param recipient Recipient that was meant to receive failed payment
     */
    function withdrawAllFailedCredits(address payable recipient) external;

    /**
     * @notice Update primary fee for a sale
     * @param saleId ID of sale being updated
     * @param primaryFee New primary fee for sale
     */
    function updatePrimaryFee(uint256 saleId, PrimaryFeeInfo calldata primaryFee) external;

    /**
     * @notice Update merkleroot for a sale
     * @param saleId ID of sale being updated
     * @param _newMerkleroot New merkleroot for sale
     */
    function updateMerkleroot(uint256 saleId, bytes32 _newMerkleroot) external;

    /**
     * @notice Update the platform address
     * @param _platform New platform
     */
    function updatePlatformAddress(address _platform) external;

    /**
     * @notice Return a sale based on its sale ID
     * @param saleId ID of sale being returned
     */
    function getSale(uint256 saleId) external view returns (Sale memory);
}