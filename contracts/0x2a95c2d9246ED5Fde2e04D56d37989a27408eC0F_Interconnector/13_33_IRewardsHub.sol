// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./IMToken.sol";
import "./ILinkageLeaf.sol";

interface IRewardsHub is ILinkageLeaf {
    event DistributedSupplierMnt(IMToken mToken, address supplier, uint256 mntDelta, uint256 mntSupplyIndex);
    event DistributedBorrowerMnt(IMToken mToken, address borrower, uint256 mntDelta, uint256 mntBorrowIndex);
    event EmissionRewardAccrued(address account, uint256 amount);
    event RepresentativeRewardAccrued(address account, address provider, uint256 amount);
    event BuybackRewardAccrued(address account, uint256 amount);

    event RewardUnlocked(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event MntGranted(address recipient, uint256 amount);

    event MntSupplyEmissionRateUpdated(IMToken mToken, uint256 newSupplyEmissionRate);
    event MntBorrowEmissionRateUpdated(IMToken mToken, uint256 newBorrowEmissionRate);

    /**
     * @notice get keccak-256 hash of gatekeeper
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of timelock
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice Gets the rate at which MNT is distributed to the corresponding supply market (per block)
     */
    function mntSupplyEmissionRate(IMToken) external view returns (uint256);

    /**
     * @notice Gets the rate at which MNT is distributed to the corresponding borrow market (per block)
     */
    function mntBorrowEmissionRate(IMToken) external view returns (uint256);

    /**
     * @notice Gets the MNT market supply state for each market
     */
    function mntSupplyState(IMToken) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets the MNT market borrow state for each market
     */
    function mntBorrowState(IMToken) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets the MNT supply index and block number for each market
     */
    function mntSupplierState(IMToken, address) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets the MNT borrow index and block number for each market
     */
    function mntBorrowerState(IMToken, address) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets summary amount of available and delayed balances of an account.
     */
    function totalBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Gets amount of MNT that can be withdrawn from an account at this block.
     */
    function availableBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Initializes market in RewardsHub. Should be called once from Supervisor.supportMarket
     * @dev RESTRICTION: Supervisor only
     */
    function initMarket(IMToken mToken) external;

    /**
     * @notice Accrues MNT to the market by updating the borrow and supply indexes
     * @dev This method doesn't update MNT index history in Minterest NFT.
     * @param market The market whose supply and borrow index to update
     * @return (MNT supply index, MNT borrow index)
     */
    function updateAndGetMntIndexes(IMToken market) external returns (uint224, uint224);

    /**
     * @notice Shorthand function to distribute MNT emissions from supplies of one market.
     */
    function distributeSupplierMnt(IMToken mToken, address account) external;

    /**
     * @notice Shorthand function to distribute MNT emissions from borrows of one market.
     */
    function distributeBorrowerMnt(IMToken mToken, address account) external;

    /**
     * @notice Updates market indexes and distributes tokens (if any) for holder
     * @dev Updates indexes and distributes only for those markets where the holder have a
     * non-zero supply or borrow balance.
     * @param account The address to distribute MNT for
     */
    function distributeAllMnt(address account) external;

    /**
     * @notice Distribute all MNT accrued by the accounts
     * @param accounts The addresses to distribute MNT for
     * @param mTokens The list of markets to distribute MNT in
     * @param borrowers Whether or not to distribute MNT earned by borrowing
     * @param suppliers Whether or not to distribute MNT earned by supplying
     */
    function distributeMnt(
        address[] memory accounts,
        IMToken[] memory mTokens,
        bool borrowers,
        bool suppliers
    ) external;

    /**
     * @notice Accrues buyback reward
     * @dev RESTRICTION: Buyback only
     */
    function accrueBuybackReward(address account, uint256 amount) external;

    /**
     * @notice Gets part of delayed rewards that is unlocked and have become available.
     */
    function getUnlockableRewards(address account) external view returns (uint256);

    /**
     * @notice Transfers available part of MNT rewards to the sender.
     * This will decrease accounts buyback and voting weights.
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Transfers
     * @dev RESTRICTION: Admin only
     */
    function grant(address recipient, uint256 amount) external;

    /**
     * @notice Set MNT borrow and supply emission rates for a single market
     * @param mToken The market whose MNT emission rate to update
     * @param newMntSupplyEmissionRate New supply MNT emission rate for market
     * @param newMntBorrowEmissionRate New borrow MNT emission rate for market
     * @dev RESTRICTION Timelock only
     */
    function setMntEmissionRates(
        IMToken mToken,
        uint256 newMntSupplyEmissionRate,
        uint256 newMntBorrowEmissionRate
    ) external;
}