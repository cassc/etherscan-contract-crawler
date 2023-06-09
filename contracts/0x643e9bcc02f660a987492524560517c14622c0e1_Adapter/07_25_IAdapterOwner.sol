// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IAdapterOwner {
    struct AdapterConfig {
        // Minimum number of blocks a request must wait before being fulfilled.
        uint16 minimumRequestConfirmations;
        // Maximum gas limit for fulfillRandomness requests.
        uint32 maxGasLimit;
        // Reentrancy protection.
        bool reentrancyLock;
        // Gas to cover group payment after we calculate the payment.
        // We make it configurable in case those operations are repriced.
        uint32 gasAfterPaymentCalculation;
        // Gas except callback during fulfillment of randomness. Only used for estimating inflight cost.
        uint32 gasExceptCallback;
        // The assigned group is exclusive for fulfilling the task within this block window
        uint256 signatureTaskExclusiveWindow;
        // reward per signature for every participating node
        uint256 rewardPerSignature;
        // reward per signature for the committer
        uint256 committerRewardPerSignature;
    }

    struct FeeConfig {
        // Flat fee charged per fulfillment in millionths of arpa
        uint32 fulfillmentFlatFeeEthPPMTier1;
        uint32 fulfillmentFlatFeeEthPPMTier2;
        uint32 fulfillmentFlatFeeEthPPMTier3;
        uint32 fulfillmentFlatFeeEthPPMTier4;
        uint32 fulfillmentFlatFeeEthPPMTier5;
        uint24 reqsForTier2;
        uint24 reqsForTier3;
        uint24 reqsForTier4;
        uint24 reqsForTier5;
    }

    struct FlatFeeConfig {
        FeeConfig config;
        uint16 flatFeePromotionGlobalPercentage;
        bool isFlatFeePromotionEnabledPermanently;
        uint256 flatFeePromotionStartTimestamp;
        uint256 flatFeePromotionEndTimestamp;
    }

    struct ReferralConfig {
        bool isReferralEnabled;
        uint16 freeRequestCountForReferrer;
        uint16 freeRequestCountForReferee;
    }

    /**
     * @notice Sets the configuration of the adapter
     * @param minimumRequestConfirmations global min for request confirmations
     * @param maxGasLimit global max for request gas limit
     * @param gasAfterPaymentCalculation gas used in doing accounting after completing the gas measurement
     * @param signatureTaskExclusiveWindow window in which a signature task is exclusive to the assigned group
     * @param rewardPerSignature reward per signature for every participating node
     * @param committerRewardPerSignature reward per signature for the committer
     */
    function setAdapterConfig(
        uint16 minimumRequestConfirmations,
        uint32 maxGasLimit,
        uint32 gasAfterPaymentCalculation,
        uint32 gasExceptCallback,
        uint256 signatureTaskExclusiveWindow,
        uint256 rewardPerSignature,
        uint256 committerRewardPerSignature
    ) external;

    /**
     * @notice Sets the flat fee configuration of the adapter
     * @param flatFeeConfig flat fee tier configuration
     * @param flatFeePromotionGlobalPercentage global percentage of flat fee promotion
     * @param isFlatFeePromotionEnabledPermanently whether flat fee promotion is enabled permanently
     * @param flatFeePromotionStartTimestamp flat fee promotion start timestamp
     * @param flatFeePromotionEndTimestamp flat fee promotion end timestamp
     */
    function setFlatFeeConfig(
        FeeConfig memory flatFeeConfig,
        uint16 flatFeePromotionGlobalPercentage,
        bool isFlatFeePromotionEnabledPermanently,
        uint256 flatFeePromotionStartTimestamp,
        uint256 flatFeePromotionEndTimestamp
    ) external;

    /**
     * @notice Sets the referral configuration of the adapter
     * @param isReferralEnabled whether referral is enabled
     * @param freeRequestCountForReferrer free request count for referrer
     * @param freeRequestCountForReferee free request count for referee
     */
    function setReferralConfig(
        bool isReferralEnabled,
        uint16 freeRequestCountForReferrer,
        uint16 freeRequestCountForReferee
    ) external;

    /**
     * @notice Sets free request count for subscriptions
     * @param subIds subscription ids
     * @param freeRequestCounts free request count for each subscription
     */
    function setFreeRequestCount(uint64[] memory subIds, uint64[] memory freeRequestCounts) external;

    /**
     * @notice Owner cancel subscription, sends remaining eth directly to the subscription owner
     * @param subId subscription id
     * @dev notably can be called even if there are pending requests
     */
    function ownerCancelSubscription(uint64 subId) external;
}