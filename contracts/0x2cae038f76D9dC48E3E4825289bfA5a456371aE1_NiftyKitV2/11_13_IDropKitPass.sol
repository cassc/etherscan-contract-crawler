// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDropKitPass {
    struct FeeEntry {
        uint96 value;
        bool isValue;
    }

    struct Pass {
        uint256 price;
        bool isValue;
    }

    event PassCreated(uint256 indexed stageId, uint96 indexed feeRate);

    event PassRedeemed(
        uint256 indexed stageId,
        uint96 indexed feeRate,
        bytes32 indexed hash
    );

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