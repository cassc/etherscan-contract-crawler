// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface ITierPricingManager {
    /// @notice Emitted when the current tier index has been shifted.
    event CurrentTierSet(Tier newCurrentTier);

    /// @notice Emitted when a new set of tiers has been set.
    event TiersUpdated(Tier[] tiers);

    /// @notice Emitted when the public token mint limit has been set.
    event PublicTokenLimitSet(uint256 publicMintTokenLimit);

    /// @notice Thrown when the supplied tier size is not.
    error TierMustContainAtLeastOneEntry();

    /// @notice Thrown when the tier threshold is smaller than the previous tier.
    error InvalidTierThresholdSupplied(uint256 tierIndex);

    /// @notice Thrown when the user-cap is smaller than the previous tier.
    error InvalidTierCapPerUser(uint256 tierIndex);

    /// @notice Thrown when user cap is larger than the tier threshold.
    error TierCapLargerThanThreshold(uint256 tierIndex, uint256 cap, uint256 threshold);

    struct Tier {
        /// @dev The price for a single item
        uint256 price;
        /// @dev Total amount of total tokens that can be minted
        uint64 threshold;
        /// @dev Total amount of tokens that can be bought by a single user
        uint64 capPerUser;
    }

    /// @notice Set tiers.
    /// @param tiers An array of token-sale describing tiers. The order of the tiers in the array is important.
    ///        price - The price for a single NFT.
    ///        threshold - Total amount of total tokens that can be minted. Each subsequent threshold needs to be larger then the previous one.
    ///        capPerUser - Total amount of tokens that can be bought by a single user. Each subsequent cap needs to be larger or equal than the previous one.
    function setTiers(Tier[] calldata tiers) external;

    /// @notice Bump the tier index.
    function bumpTier() external;

    /// @notice Get currently stored tier settings.
    /// @return tiers An array of token-sale describing tiers.
    function getTiers() external view returns (Tier[] memory tiers);

    /// @notice Get information regarding the current tier.
    /// @return currentTier The current tier structure.
    /// @return currentTierIndex The index of the current tier withing the `tiers` array.
    /// @return totalTiers The total number of tiers.
    function getCurrentTier()
        external
        returns (
            Tier memory currentTier,
            uint256 currentTierIndex,
            uint256 totalTiers
        );

    /// @notice Get information about the very last tier.
    function getLastTier() external returns (Tier memory lastTier);
}