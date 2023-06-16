// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "./types/TieredPricingDataTypes.sol";

interface ITieredPricingEventsV0 {
    event PlatformFeeReceiverUpdated(address newPlatformFeeReceiver);

    event TierAdded(
        bytes32 indexed namespace,
        bytes32 indexed tierId,
        string indexed tierName,
        uint256 tierPrice,
        address tierCurrency,
        ITieredPricingDataTypesV0.FeeTypes feeType
    );
    event TierUpdated(
        bytes32 indexed namespace,
        bytes32 indexed tierId,
        string indexed tierName,
        uint256 tierPrice,
        address tierCurrency,
        ITieredPricingDataTypesV0.FeeTypes feeType
    );
    event TierRemoved(bytes32 indexed namespace, bytes32 indexed tierId);
    event AddressAddedToTier(bytes32 indexed namespace, address indexed account, bytes32 indexed tierId);
    event AddressRemovedFromTier(bytes32 indexed namespace, address indexed account, bytes32 indexed tierId);
}

interface ITieredPricingGettersV0 {
    function getTiersForNamespace(bytes32 _namespace)
        external
        view
        returns (bytes32[] memory tierIds, ITieredPricingDataTypesV0.Tier[] memory tiers);

    function getDefaultTierForNamespace(bytes32 _namespace)
        external
        view
        returns (bytes32 tierId, ITieredPricingDataTypesV0.Tier memory tier);

    function getDeploymentFee(address _account)
        external
        view
        returns (
            address feeReceiver,
            uint256 price,
            address currency
        );

    function getClaimFee(address _account) external view returns (address feeReceiver, uint256 price);

    function getCollectorFee(address _account)
        external
        view
        returns (
            address feeReceiver,
            uint256 price,
            address currency
        );

    function getFee(bytes32 _namespace, address _account)
        external
        view
        returns (
            address feeReceiver,
            uint256 price,
            ITieredPricingDataTypesV0.FeeTypes feeType,
            address currency
        );

    function getTierDetails(bytes32 _namespace, bytes32 _tierId)
        external
        view
        returns (ITieredPricingDataTypesV0.Tier memory tier);

    function getPlatformFeeReceiver() external view returns (address feeReceiver);
}

interface ITieredPricingV0 is ITieredPricingEventsV0, ITieredPricingGettersV0 {
    function setPlatformFeeReceiver(address _platformFeeReceiver) external;

    function addTier(bytes32 _namespace, ITieredPricingDataTypesV0.Tier calldata _tierDetails) external;

    function updateTier(
        bytes32 _namespace,
        bytes32 _tierId,
        ITieredPricingDataTypesV0.Tier calldata _tierDetails
    ) external;

    function removeTier(bytes32 _namespace, bytes32 _tierId) external;

    function addAddressToTier(
        bytes32 _namespace,
        address _account,
        bytes32 _tierId
    ) external;

    function removeAddressFromTier(bytes32 _namespace, address _account) external;
}

interface ITieredPricingEventsV1 {
    event DefaultTierUpdated(bytes32 indexed namespace, bytes32 indexed tierId);
}

interface ITieredPricingV1 is ITieredPricingEventsV1 {
    function setDefaultTier(bytes32 _namespace, bytes32 _tierId) external;
}