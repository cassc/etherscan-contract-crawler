// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDropKitPass {
    struct FeeEntry {
        uint96 value;
        bool isValue;
    }

    struct PricingEntry {
        uint256 price;
        bool isValue;
    }

    event PassOptionCreated(
        uint256 indexed stageId,
        uint96 indexed feeRate,
        uint256 indexed price
    );

    event PassOptionUpdated(
        uint256 indexed stageId,
        uint96 indexed feeRate,
        uint256 indexed price,
        bool isValue
    );

    event PassOptionRedeemed(
        uint256 indexed stageId,
        uint96 indexed feeRate,
        bytes32 indexed data
    );

    event PassOptionPurchased(uint256 indexed stageId, uint96 indexed feeRate);

    event PassActivated(uint256 indexed tokenId, address indexed owner);

    event PassDeactivated(uint256 indexed tokenId, address indexed owner);

    event SaleStarted(
        uint256 indexed stageId,
        uint256 maxAmount,
        uint256 maxPerWallet,
        uint256 maxPerMint,
        bool presale
    );

    event SaleStopped(uint256 indexed stageId);

    /**
     * @dev Contract upgradeable initializer
     */
    function initialize(
        string memory name,
        string memory symbol,
        address treasury,
        address royalty,
        uint96 royaltyFee,
        uint96 defaultFeeRate
    ) external;

    /**
     * @dev Batch mints feeRate tokens for a given stage
     */
    function batchAirdrop(
        uint256 stageId,
        address[] calldata recipients,
        uint96[] calldata feeRates
    ) external;

    /**
     * @dev Gets the fee rate for a given token id
     */
    function getFeeRate(uint256 tokenId) external view returns (uint96);

    /**
     * @dev Gets the fee rate for a given address
     */
    function getFeeRateOf(address owner) external view returns (uint96);
}