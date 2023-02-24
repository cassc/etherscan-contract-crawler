// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./ISupervisor.sol";
import "./IRewardsHub.sol";
import "./IMToken.sol";
import "./ILinkageLeaf.sol";

interface IEmissionBooster is IAccessControl, ILinkageLeaf {
    /**
     * @notice Emitted when new Tier was created
     */
    event NewTierCreated(uint256 createdTier, uint32 endBoostBlock, uint256 emissionBoost);

    /**
     * @notice Emitted when Tier was enabled
     */
    event TierEnabled(
        IMToken market,
        uint256 enabledTier,
        uint32 startBoostBlock,
        uint224 mntSupplyIndex,
        uint224 mntBorrowIndex
    );

    /**
     * @notice Emitted when emission boost mode was enabled
     */
    event EmissionBoostEnabled(address caller);

    /**
     * @notice Emitted when MNT supply index of the tier ending on the market was saved to storage
     */
    event SupplyIndexUpdated(address market, uint256 nextTier, uint224 newIndex, uint32 endBlock);

    /**
     * @notice Emitted when MNT borrow index of the tier ending on the market was saved to storage
     */
    event BorrowIndexUpdated(address market, uint256 nextTier, uint224 newIndex, uint32 endBlock);

    /**
     * @notice get the Tier for each MinterestNFT token
     */
    function tokenTier(uint256) external view returns (uint256);

    /**
     * @notice get a list of all created Tiers
     */
    function tiers(uint256)
        external
        view
        returns (
            uint32,
            uint32,
            uint256
        );

    /**
     * @notice get status of emission boost mode.
     */
    function isEmissionBoostingEnabled() external view returns (bool);

    /**
     * @notice get Stored markets indexes per block.
     */
    function marketSupplyIndexes(IMToken, uint256) external view returns (uint256);

    /**
     * @notice get Stored markets indexes per block.
     */
    function marketBorrowIndexes(IMToken, uint256) external view returns (uint256);

    /**
     * @notice Mint token hook which is called from MinterestNFT.mint() and sets specific
     *      settings for this NFT
     * @param to_ NFT ovner
     * @param ids_ NFTs IDs
     * @param amounts_ Amounts of minted NFTs per tier
     * @param tiers_ NFT tiers
     * @dev RESTRICTION: MinterestNFT only
     */
    function onMintToken(
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        uint256[] memory tiers_
    ) external;

    /**
     * @notice Transfer token hook which is called from MinterestNFT.transfer() and sets specific
     *      settings for this NFT
     * @param from_ Address of the tokens previous owner. Should not be zero (minter).
     * @param to_ Address of the tokens new owner.
     * @param ids_ NFTs IDs
     * @param amounts_ Amounts of minted NFTs per tier
     * @dev RESTRICTION: MinterestNFT only
     */
    function onTransferToken(
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    ) external;

    /**
     * @notice Enables emission boost mode.
     * @dev Admin function for enabling emission boosts.
     * @dev RESTRICTION: Whitelist only
     */
    function enableEmissionBoosting() external;

    /**
     * @notice Creates new Tiers for MinterestNFT tokens
     * @dev Admin function for creating Tiers
     * @param endBoostBlocks Emission boost end blocks for created Tiers
     * @param emissionBoosts Emission boosts for created Tiers, scaled by 1e18
     * Note: The arrays passed to the function must be of the same length and the order of the elements must match
     *      each other
     * @dev RESTRICTION: Admin only
     */
    function createTiers(uint32[] memory endBoostBlocks, uint256[] memory emissionBoosts) external;

    /**
     * @notice Enables emission boost in specified Tiers
     * @param tiersForEnabling Tier for enabling emission boost
     * @dev RESTRICTION: Admin only
     */
    function enableTiers(uint256[] memory tiersForEnabling) external;

    /**
     * @notice Return the number of created Tiers
     * @return The number of created Tiers
     */
    function getNumberOfTiers() external view returns (uint256);

    /**
     * @notice Checks if the specified Tier is active
     * @param tier_ The Tier that is being checked
     */
    function isTierActive(uint256 tier_) external view returns (bool);

    /**
     * @notice Checks if the specified Tier exists
     * @param tier_ The Tier that is being checked
     */
    function tierExists(uint256 tier_) external view returns (bool);

    /**
     * @param account_ The address of the account
     * @return Bitmap of all accounts tiers
     */
    function getAccountTiersBitmap(address account_) external view returns (uint256);

    /**
     * @param account_ The address of the account to check if they have any tokens with tier
     */
    function isAccountHaveTiers(address account_) external view returns (bool);

    /**
     * @param account_ Address of the account
     * @return tier Highest tier number
     * @return boost Highest boost amount
     */
    function getCurrentAccountBoost(address account_) external view returns (uint256 tier, uint256 boost);

    /**
     * @notice Calculates emission boost for the account.
     * @param market_ Market for which we are calculating emission boost
     * @param account_ The address of the account for which we are calculating emission boost
     * @param userLastIndex_ The account's last updated mntBorrowIndex or mntSupplyIndex
     * @param userLastBlock_ The block number in which the index for the account was last updated
     * @param marketIndex_ The market's current mntBorrowIndex or mntSupplyIndex
     * @param isSupply_ boolean value, if true, then return calculate emission boost for suppliers
     * @return boostedIndex Boost part of delta index
     */
    function calculateEmissionBoost(
        IMToken market_,
        address account_,
        uint256 userLastIndex_,
        uint256 userLastBlock_,
        uint256 marketIndex_,
        bool isSupply_
    ) external view returns (uint256 boostedIndex);

    /**
     * @notice Update MNT supply index for market for NFT tiers that are expired but not yet updated.
     * @dev This function checks if there are tiers to update and process them one by one:
     *      calculates the MNT supply index depending on the delta index and delta blocks between
     *      last MNT supply index update and the current state,
     *      emits SupplyIndexUpdated event and recalculates next tier to update.
     * @param market Address of the market to update
     * @param lastUpdatedBlock Last updated block number
     * @param lastUpdatedIndex Last updated index value
     * @param currentSupplyIndex Current MNT supply index value
     * @dev RESTRICTION: RewardsHub only
     */
    function updateSupplyIndexesHistory(
        IMToken market,
        uint256 lastUpdatedBlock,
        uint256 lastUpdatedIndex,
        uint256 currentSupplyIndex
    ) external;

    /**
     * @notice Update MNT borrow index for market for NFT tiers that are expired but not yet updated.
     * @dev This function checks if there are tiers to update and process them one by one:
     *      calculates the MNT borrow index depending on the delta index and delta blocks between
     *      last MNT borrow index update and the current state,
     *      emits BorrowIndexUpdated event and recalculates next tier to update.
     * @param market Address of the market to update
     * @param lastUpdatedBlock Last updated block number
     * @param lastUpdatedIndex Last updated index value
     * @param currentBorrowIndex Current MNT borrow index value
     * @dev RESTRICTION: RewardsHub only
     */
    function updateBorrowIndexesHistory(
        IMToken market,
        uint256 lastUpdatedBlock,
        uint256 lastUpdatedIndex,
        uint256 currentBorrowIndex
    ) external;

    /**
     * @notice Get Id of NFT tier to update next on provided market MNT index, supply or borrow
     * @param market Market for which should the next Tier to update be updated
     * @param isSupply_ Flag that indicates whether MNT supply or borrow market should be updated
     * @return Id of tier to update
     */
    function getNextTierToBeUpdatedIndex(IMToken market, bool isSupply_) external view returns (uint256);
}