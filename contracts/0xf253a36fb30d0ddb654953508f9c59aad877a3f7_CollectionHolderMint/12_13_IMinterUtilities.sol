// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Minter Utilities Interface
 * @notice Interface for the MinterUtilities contract, which provides utility functions for the minter.
 */
interface IMinterUtilities {
    /**
     * @dev Emitted when the price of a tier is updated.
     * @param tier The tier whose price is updated.
     * @param price The new price for the tier.
     */
    event TierPriceUpdated(uint256 tier, uint256 price);

    /**
     * @dev Emitted when the lockup period of a tier is updated.
     * @param tier The tier whose lockup period is updated.
     * @param lockup The new lockup period for the tier.
     */
    event TierLockupUpdated(uint256 tier, uint256 lockup);

    /**
     * @dev Represents pricing and lockup information for a specific tier.
     */
    struct TierInfo {
        uint256 price;
        uint256 lockup;
    }

    /**
     * @dev Represents a tier and quantity of NFTs.
     */
    struct Cart {
        uint8 tier;
        uint256 quantity;
    }

    /**
     * @notice Calculates the total price for a given quantity of NFTs in a specific tier.
     * @param tier The tier to calculate the price for.
     * @param quantity The quantity of NFTs to calculate the price for.
     * @return The total price in wei for the given quantity in the specified tier.
     */
    function calculatePrice(
        uint8 tier,
        uint256 quantity
    ) external view returns (uint256);

    /**
     * @notice Returns the quantity of NFTs left that can be minted by the given recipient.
     * @param passportHolderMinter The address of the PassportHolderMinter contract.
     * @param friendsAndFamilyMinter The address of the FriendsAndFamilyMinter contract.
     * @param target The address of the target contract (ICre8ors contract).
     * @param recipient The recipient's address.
     * @return The quantity of NFTs that can still be minted by the recipient.
     */
    function quantityLeft(
        address passportHolderMinter,
        address friendsAndFamilyMinter,
        address target,
        address recipient
    ) external view returns (uint256);

    /**
     * @notice Calculates the total cost for a given list of NFTs in different tiers.
     * @param carts An array of Cart struct representing the tiers and quantities.
     * @return The total cost in wei for the given list of NFTs.
     */
    function calculateTotalCost(
        uint256[] memory carts
    ) external view returns (uint256);

    /**
     * @dev Calculates the unlock price for a given tier and minting option.
     * @param tier The tier for which to calculate the unlock price.
     * @param freeMint A boolean flag indicating whether the minting option is free or not.
     * @return The calculated unlock price in wei.
     */
    function calculateUnlockPrice(
        uint8 tier,
        bool freeMint
    ) external view returns (uint256);

    /**
     * @notice Calculates the lockup period for a specific tier.
     * @param tier The tier to calculate the lockup period for.
     * @return The lockup period in seconds for the specified tier.
     */
    function calculateLockupDate(uint8 tier) external view returns (uint256);

    /**
     * @notice Calculates the total quantity of NFTs in a given list of Cart structs.
     * @param carts An array of Cart struct representing the tiers and quantities.
     * @return Total quantity of NFTs in the given list of carts.
     */

    function calculateTotalQuantity(
        uint256[] memory carts
    ) external view returns (uint256);

    /**
     * @notice Updates the prices for all tiers in the MinterUtilities contract.
     * @param tierPrices A bytes array representing the new prices for all tiers (in wei).
     */
    function updateAllTierPrices(bytes calldata tierPrices) external;

    /**
     * @notice Sets new default lockup periods for all tiers.
     * @param lockupInfo A bytes array representing the new lockup periods for all tiers (in seconds).
     */
    function setNewDefaultLockups(bytes calldata lockupInfo) external;

    /**
     * @notice Retrieves tier information for a specific tier ID.
     * @param tierId The ID of the tier to get information for.
     * @return TierInfo tier information struct containing lockup duration and unlock price in wei.
     */
    function getTierInfo(uint8 tierId) external view returns (TierInfo memory);

    /**
     * @notice Retrieves all tier information.
     * @return bytes data of tier information struct containing lockup duration and unlock price in wei.
     */
    function getTierInfo() external view returns (bytes memory);
}