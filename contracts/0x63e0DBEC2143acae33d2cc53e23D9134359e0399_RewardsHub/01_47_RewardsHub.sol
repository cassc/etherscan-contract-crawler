// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./interfaces/IBDSystem.sol";
import "./interfaces/IEmissionBooster.sol";
import "./interfaces/IMnt.sol";
import "./interfaces/IMToken.sol";
import "./interfaces/IRewardsHub.sol";
import "./libraries/ErrorCodes.sol";
import "./libraries/PauseControl.sol";
import "./InterconnectorLeaf.sol";

contract RewardsHub is IRewardsHub, Initializable, ReentrancyGuard, AccessControl, PauseControl, InterconnectorLeaf {
    using SafeCast for uint256;
    using SafeERC20Upgradeable for IMnt;

    uint32 internal constant BUCKETS = 12;
    uint32 internal constant DELAY_DURATION = 60 * 60 * 24 * 365; // 31536000 seconds
    uint32 internal constant BUCKET_DURATION = DELAY_DURATION / BUCKETS; // 2628000 seconds
    bytes32 internal constant BUYBACK_SOURCE = "Buyback";
    bytes32 internal constant BD_SYSTEM_SOURCE = "BDSystem";

    struct IndexState {
        uint224 index;
        uint32 block; // block number of the last index update
    }

    struct RewardDelayInfo {
        uint32 periodOffset;
        uint32 lastPayoutTime;
        uint192 currentPeriodReward; // Stores up to 6e+57
    }

    /// @dev The right part is the keccak-256 hash of "GATEKEEPER"
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);
    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    uint256 internal constant EXP_SCALE = 1e18;
    uint256 internal constant DOUBLE_SCALE = 1e36;
    uint256 internal constant BUYBACK_INDEX_SCALE = 1e36;

    /// @notice The initial MNT index for a market
    uint224 internal constant MNT_INITIAL_INDEX = 1e36;
    /// @dev Delay period duration. Claim period has the same duration.
    uint32 internal constant DELAY_PERIOD = 365 days;

    IMnt public mnt;
    IEmissionBooster public emissionBooster;
    IBDSystem public bdSystem;

    /// @dev Contains amounts of regular rewards for individual accounts.
    mapping(address => uint256) internal balances;

    // // // // // // MNT emissions

    /// @dev The rate at which MNT is distributed to the corresponding supply market (per block)
    mapping(IMToken => uint256) public mntSupplyEmissionRate;
    /// @dev The rate at which MNT is distributed to the corresponding borrow market (per block)
    mapping(IMToken => uint256) public mntBorrowEmissionRate;
    /// @dev The MNT market supply state for each market
    mapping(IMToken => IndexState) public mntSupplyState;
    /// @dev The MNT market borrow state for each market
    mapping(IMToken => IndexState) public mntBorrowState;
    /// @dev The MNT supply index and block number for each market
    /// for each supplier as of the last time they accrued MNT
    mapping(IMToken => mapping(address => IndexState)) public mntSupplierState;
    /// @dev The MNT borrow index and block number for each market
    /// for each supplier as of the last time they accrued MNT
    mapping(IMToken => mapping(address => IndexState)) public mntBorrowerState;

    // // // // // // Delay logic

    mapping(address => RewardDelayInfo) internal delayInfos;
    mapping(address => uint256[BUCKETS]) internal accountBuckets;
    mapping(bytes32 => mapping(address => uint32)) internal lastAccrueBucketBySource;

    /**
     * @notice Initialise RewardsHub contract
     * @param admin_ admin address
     * @param mnt_ Mnt contract address
     * @param emissionBooster_ EmissionBooster contract address
     * @param bdSystem_ BDSystem contract address
     */
    function initialize(
        address admin_,
        IMnt mnt_,
        IEmissionBooster emissionBooster_,
        IBDSystem bdSystem_
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
        _grantRole(TIMELOCK, admin_);

        mnt = mnt_;
        emissionBooster = emissionBooster_;
        bdSystem = bdSystem_;
    }

    // // // // Getters

    /// @inheritdoc IRewardsHub
    function totalBalanceOf(address account) external view returns (uint256) {
        return balances[account] + getAccruedRewards(account);
    }

    /// @inheritdoc IRewardsHub
    function availableBalanceOf(address account) external view returns (uint256) {
        return balances[account] + getUnlockableRewards(account);
    }

    function getAccruedRewards(address account) public view returns (uint256) {
        RewardDelayInfo memory info = delayInfos[account];
        if (info.lastPayoutTime == 0) return 0; // Should be initialized at first accrue

        (uint256 fullyUnlocked, ) = _calculateUnlockable(
            info,
            accountBuckets[account],
            info.lastPayoutTime + DELAY_DURATION
        );
        return fullyUnlocked;
    }

    /// @inheritdoc IRewardsHub
    function getUnlockableRewards(address account) public view returns (uint256) {
        RewardDelayInfo memory info = delayInfos[account];
        if (info.lastPayoutTime == 0) return 0; // Should be initialized at first accrue

        uint32 rightNow = getTimestamp();
        if (rightNow == info.lastPayoutTime) return 0;

        (uint256 fullyUnlocked, ) = _calculateUnlockable(info, accountBuckets[account], rightNow);
        return fullyUnlocked;
    }

    function getDelayInfo(address account)
        external
        view
        returns (
            uint32 periodOffset,
            uint32 lastPayoutTime,
            uint192 currentPeriodReward
        )
    {
        RewardDelayInfo memory di = delayInfos[account];
        return (di.periodOffset, di.lastPayoutTime, di.currentPeriodReward);
    }

    function getBuckets(address account) external view returns (uint256[BUCKETS] memory) {
        return accountBuckets[account];
    }

    function getLastAccruePeriod(address account, bytes32 source) external view returns (uint32) {
        return lastAccrueBucketBySource[source][account];
    }

    // // // // MNT emissions

    /// @inheritdoc IRewardsHub
    function initMarket(IMToken mToken) external {
        require(msg.sender == address(supervisor()), ErrorCodes.UNAUTHORIZED);
        require(
            mntSupplyState[mToken].index == 0 && mntBorrowState[mToken].index == 0,
            ErrorCodes.MARKET_ALREADY_LISTED
        );

        // Initialize MNT emission indexes of the market
        uint32 currentBlock = getBlockNumber();
        mntSupplyState[mToken] = IndexState({index: MNT_INITIAL_INDEX, block: currentBlock});
        mntBorrowState[mToken] = IndexState({index: MNT_INITIAL_INDEX, block: currentBlock});
    }

    /**
     * @dev Calculates the new state of the market.
     * @param state The block number the index was last updated at and the market's last updated mntBorrowIndex
     * or mntSupplyIndex in this block
     * @param emissionRate MNT rate that each market currently receives (supply or borrow)
     * @param totalBalance Total market balance (totalSupply or totalBorrow)
     * Note: this method doesn't return anything, it only mutates memory variable `state`.
     */
    function calculateUpdatedMarketState(
        IndexState memory state,
        uint256 emissionRate,
        uint256 totalBalance
    ) internal view {
        uint256 blockNumber = getBlockNumber();

        if (emissionRate > 0) {
            uint256 deltaBlocks = blockNumber - state.block;
            uint256 mntAccrued_ = deltaBlocks * emissionRate;
            uint256 ratio = totalBalance > 0 ? (mntAccrued_ * DOUBLE_SCALE) / totalBalance : 0;
            // index = lastUpdatedIndex + deltaBlocks * emissionRate / amount
            state.index += ratio.toUint224();
        }

        state.block = uint32(blockNumber);
    }

    /**
     * @dev Gets current market state (the block number and MNT supply index)
     * @param mToken The market whose MNT supply index to get
     */
    function getUpdatedMntSupplyIndex(IMToken mToken) internal view returns (IndexState memory supplyState) {
        supplyState = mntSupplyState[mToken];
        require(supplyState.index >= MNT_INITIAL_INDEX, ErrorCodes.MARKET_NOT_LISTED);
        calculateUpdatedMarketState(supplyState, mntSupplyEmissionRate[mToken], mToken.totalSupply());
        return supplyState;
    }

    /**
     * @dev Gets current market state (the block number and MNT supply index)
     * @param mToken The market whose MNT supply index to get
     */
    function getUpdatedMntBorrowIndex(IMToken mToken, uint224 marketBorrowIndex)
        internal
        view
        returns (IndexState memory borrowState)
    {
        borrowState = mntBorrowState[mToken];
        require(borrowState.index >= MNT_INITIAL_INDEX, ErrorCodes.MARKET_NOT_LISTED);
        uint256 borrowAmount = (mToken.totalBorrows() * EXP_SCALE) / marketBorrowIndex;
        calculateUpdatedMarketState(borrowState, mntBorrowEmissionRate[mToken], borrowAmount);
        return borrowState;
    }

    /**
     * @dev Accrue MNT to the market by updating the MNT supply index.
     * Index is a cumulative sum of the MNT per mToken accrued.
     * @param mToken The market whose MNT supply index to update
     */
    function updateMntSupplyIndex(IMToken mToken) internal {
        uint32 lastUpdatedBlock = mntSupplyState[mToken].block;
        if (lastUpdatedBlock == getBlockNumber()) return;

        if (emissionBooster.isEmissionBoostingEnabled()) {
            uint224 lastUpdatedIndex = mntSupplyState[mToken].index;
            IndexState memory currentState = getUpdatedMntSupplyIndex(mToken);
            mntSupplyState[mToken] = currentState;
            // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
            emissionBooster.updateSupplyIndexesHistory(mToken, lastUpdatedBlock, lastUpdatedIndex, currentState.index);
        } else {
            mntSupplyState[mToken] = getUpdatedMntSupplyIndex(mToken);
        }
    }

    /**
     * @dev Accrue MNT to the market by updating the MNT borrow index.
     * Index is a cumulative sum of the MNT per mToken accrued.
     * @param mToken The market whose MNT borrow index to update
     * @param marketBorrowIndex The market's last updated BorrowIndex
     */
    function updateMntBorrowIndex(IMToken mToken, uint224 marketBorrowIndex) internal {
        uint32 lastUpdatedBlock = mntBorrowState[mToken].block;
        if (lastUpdatedBlock == getBlockNumber()) return;

        if (emissionBooster.isEmissionBoostingEnabled()) {
            uint224 lastUpdatedIndex = mntBorrowState[mToken].index;
            IndexState memory currentState = getUpdatedMntBorrowIndex(mToken, marketBorrowIndex);
            mntBorrowState[mToken] = currentState;
            // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
            emissionBooster.updateBorrowIndexesHistory(mToken, lastUpdatedBlock, lastUpdatedIndex, currentState.index);
        } else {
            mntBorrowState[mToken] = getUpdatedMntBorrowIndex(mToken, marketBorrowIndex);
        }
    }

    /// @inheritdoc IRewardsHub
    function updateAndGetMntIndexes(IMToken market) external returns (uint224, uint224) {
        IndexState memory supplyState = getUpdatedMntSupplyIndex(market);
        mntSupplyState[market] = supplyState;

        uint224 borrowIndex = market.borrowIndex().toUint224();
        IndexState memory borrowState = getUpdatedMntBorrowIndex(market, borrowIndex);
        mntBorrowState[market] = borrowState;

        return (supplyState.index, borrowState.index);
    }

    struct EmissionsDistributionVars {
        address account;
        address representative;
        uint256 representativeBonus;
        uint256 liquidityProviderBoost;
        uint256 accruedMnt;
        uint256 unlockedMnt;
        RewardDelayInfo delayInfo;
        RewardDelayInfo reprDelayInfo;
    }

    /// @dev Basically EmissionsDistributionVars constructor
    function initDistribution(address account)
        internal
        checkPaused(DISTRIBUTION_OP)
        returns (EmissionsDistributionVars memory vars)
    {
        vars.account = account;
        vars.delayInfo = delayInfos[account];

        (
            vars.liquidityProviderBoost,
            vars.representativeBonus,
            ,
            // ^^^ skips endBlock
            vars.representative
        ) = bdSystem.providerToAgreement(account);
        if (vars.representative != address(0)) {
            vars.reprDelayInfo = delayInfos[vars.representative];
        }

        // Unlock delayed rewards once, before any new accrues from markets.
        vars.unlockedMnt = _unlockDelayed(account, vars.delayInfo);
    }

    /// @dev Accrues MNT emissions of account per market and saves result to EmissionsDistributionVars
    function updateDistributionState(
        EmissionsDistributionVars memory vars,
        IMToken mToken,
        uint256 accountBalance,
        uint224 currentMntIndex,
        IndexState storage accountIndex,
        bool isSupply
    ) internal {
        uint32 currentBlock = getBlockNumber();
        uint224 lastAccountIndex = accountIndex.index;
        uint32 lastUpdateBlock = accountIndex.block;

        if (lastAccountIndex == 0 && currentMntIndex >= MNT_INITIAL_INDEX) {
            // Covers the case where users interacted with market before its state index was set.
            // Rewards the user with MNT accrued from the start of when account rewards were first
            // set for the market.
            lastAccountIndex = MNT_INITIAL_INDEX;
            lastUpdateBlock = currentBlock;
        }

        // Update supplier's index and block to the current index and block since we are distributing accrued MNT
        accountIndex.index = currentMntIndex;
        accountIndex.block = currentBlock;

        bytes32 source = _marketSource(mToken, isSupply);
        uint256 deltaIndex = currentMntIndex - lastAccountIndex;

        // Short-circuit but call _accrueReward anyway to update last accrue period.
        if (deltaIndex == 0) {
            _accrueReward(vars.account, vars.delayInfo, lastAccrueBucketBySource[source], 0);
            return;
        }

        if (vars.representative != address(0)) {
            // Calc change in the cumulative sum of the MNT per mToken accrued (with considering BD system boosts)
            deltaIndex += (deltaIndex * vars.liquidityProviderBoost) / EXP_SCALE;
        } else {
            // Calc change in the cumulative sum of the MNT per mToken accrued (with considering NFT emission boost).
            // NFT emission boost doesn't work with liquidity provider emission boost at the same time.
            deltaIndex += emissionBooster.calculateEmissionBoost(
                mToken,
                vars.account,
                lastAccountIndex,
                lastUpdateBlock,
                currentMntIndex,
                isSupply
            );
        }

        uint256 accruedMnt = (accountBalance * deltaIndex) / DOUBLE_SCALE;
        vars.accruedMnt += accruedMnt;
        vars.unlockedMnt += _accrueReward(vars.account, vars.delayInfo, lastAccrueBucketBySource[source], accruedMnt);

        if (isSupply) emit DistributedSupplierMnt(mToken, vars.account, accruedMnt, currentMntIndex);
        else emit DistributedBorrowerMnt(mToken, vars.account, accruedMnt, currentMntIndex);
    }

    /// @dev Accumulate accrued MNT to user balance and its BDR representative if they have any.
    /// Also updates buyback and voting weights for user
    function payoutDistributionState(EmissionsDistributionVars memory vars) internal {
        delayInfos[vars.account] = vars.delayInfo; // Save delay info anyway
        if (vars.unlockedMnt > 0) {
            balances[vars.account] += vars.unlockedMnt;
            emit RewardUnlocked(vars.account, vars.unlockedMnt);
        }

        if (vars.accruedMnt == 0) return;
        emit EmissionRewardAccrued(vars.account, vars.accruedMnt);

        if (vars.representative != address(0)) {
            uint256 reprReward = (vars.accruedMnt * vars.representativeBonus) / EXP_SCALE;

            uint256 reprUnlocked = _unlockDelayed(vars.representative, vars.reprDelayInfo);
            reprUnlocked += _accrueReward(
                vars.representative,
                vars.reprDelayInfo,
                lastAccrueBucketBySource[BD_SYSTEM_SOURCE],
                reprReward
            );
            delayInfos[vars.representative] = vars.reprDelayInfo;

            if (reprUnlocked > 0) {
                balances[vars.representative] += reprUnlocked;
                emit RewardUnlocked(vars.representative, reprUnlocked);
            }

            emit RepresentativeRewardAccrued(vars.representative, vars.account, reprReward);
        }

        // Use relaxed update so it could skip if buyback update is paused
        buyback().updateBuybackAndVotingWeightsRelaxed(vars.account);
    }

    /// @inheritdoc IRewardsHub
    function distributeSupplierMnt(IMToken mToken, address account) external {
        updateMntSupplyIndex(mToken);

        EmissionsDistributionVars memory vars = initDistribution(account);
        uint256 supplyAmount = mToken.balanceOf(account);
        updateDistributionState(
            vars,
            mToken,
            supplyAmount,
            mntSupplyState[mToken].index,
            mntSupplierState[mToken][account],
            true
        );
        payoutDistributionState(vars);
    }

    /// @inheritdoc IRewardsHub
    function distributeBorrowerMnt(IMToken mToken, address account) external {
        uint224 borrowIndex = mToken.borrowIndex().toUint224();
        updateMntBorrowIndex(mToken, borrowIndex);

        EmissionsDistributionVars memory vars = initDistribution(account);
        uint256 borrowAmount = (mToken.borrowBalanceStored(account) * EXP_SCALE) / borrowIndex;
        updateDistributionState(
            vars,
            mToken,
            borrowAmount,
            mntBorrowState[mToken].index,
            mntBorrowerState[mToken][account],
            false
        );
        payoutDistributionState(vars);
    }

    /// @inheritdoc IRewardsHub
    function distributeAllMnt(address account) external nonReentrant {
        return distributeAccountMnt(account, supervisor().getAllMarkets(), true, true);
    }

    /// @inheritdoc IRewardsHub
    function distributeMnt(
        address[] calldata accounts,
        IMToken[] calldata mTokens,
        bool borrowers,
        bool suppliers
    ) external nonReentrant {
        ISupervisor cachedSupervisor = supervisor();
        for (uint256 i = 0; i < mTokens.length; i++) {
            require(cachedSupervisor.isMarketListed(mTokens[i]), ErrorCodes.MARKET_NOT_LISTED);
        }
        for (uint256 i = 0; i < accounts.length; i++) {
            distributeAccountMnt(accounts[i], mTokens, borrowers, suppliers);
        }
    }

    function distributeAccountMnt(
        address account,
        IMToken[] memory mTokens,
        bool borrowers,
        bool suppliers
    ) internal {
        EmissionsDistributionVars memory vars = initDistribution(account);

        for (uint256 i = 0; i < mTokens.length; i++) {
            IMToken mToken = mTokens[i];
            if (borrowers) {
                uint256 accountBorrowUnderlying = mToken.borrowBalanceStored(account);
                if (accountBorrowUnderlying > 0) {
                    uint224 borrowIndex = mToken.borrowIndex().toUint224();
                    updateMntBorrowIndex(mToken, borrowIndex);
                    updateDistributionState(
                        vars,
                        mToken,
                        (accountBorrowUnderlying * EXP_SCALE) / borrowIndex,
                        mntBorrowState[mToken].index,
                        mntBorrowerState[mToken][account],
                        false
                    );
                }
            }
            if (suppliers) {
                uint256 accountSupplyWrap = mToken.balanceOf(account);
                if (accountSupplyWrap > 0) {
                    updateMntSupplyIndex(mToken);
                    updateDistributionState(
                        vars,
                        mToken,
                        accountSupplyWrap,
                        mntSupplyState[mToken].index,
                        mntSupplierState[mToken][account],
                        true
                    );
                }
            }
        }

        payoutDistributionState(vars);
    }

    // // // // Rewards accrual and delay

    /// @inheritdoc IRewardsHub
    function accrueBuybackReward(address account, uint256 amount) external {
        require(msg.sender == address(buyback()), ErrorCodes.UNAUTHORIZED);

        RewardDelayInfo memory info = delayInfos[account];
        uint256 unlocked = _unlockDelayed(account, info);
        unlocked += _accrueReward(account, info, lastAccrueBucketBySource[BUYBACK_SOURCE], amount);
        delayInfos[account] = info; // always update

        if (unlocked > 0) {
            balances[account] += unlocked;
            emit RewardUnlocked(account, unlocked);
        }

        emit BuybackRewardAccrued(account, amount);

        // Do not update weights because they should be checked in Buyback after this call.
    }

    function _accrueReward(
        address account,
        RewardDelayInfo memory info,
        mapping(address => uint32) storage lastAccrueBucketMap,
        uint256 amount
    ) internal returns (uint256) {
        uint32 rightNow = getTimestamp();
        require(info.lastPayoutTime == rightNow, ErrorCodes.RH_ACCRUE_WITHOUT_UNLOCK);

        uint32 currentBucket = _bucketIndex(rightNow, info.periodOffset);
        uint32 lastAccrueBucket = lastAccrueBucketMap[account];
        lastAccrueBucketMap[account] = currentBucket; // Always update
        if (lastAccrueBucket == 0) {
            // Act like distance is 1 if its the first accrue from subject.
            lastAccrueBucket = currentBucket - 1;
        }

        // Short-circuit after lastAccrueBucket update.
        if (amount == 0) return 0;

        uint256[BUCKETS] storage buckets = accountBuckets[account];
        uint256 immediateUnlock = 0;
        uint256 periodAddition;

        if (currentBucket == lastAccrueBucket) {
            // Put whole accrued reward into current bucket.
            // One 12th of it should be unlock in current period.
            periodAddition = amount / BUCKETS;
            buckets[currentBucket % BUCKETS] += amount;
        } else {
            // Split accrued reward into {distance} parts, one for each passed period.
            // - Periods that are older than a year should be fully unlocked.
            // - Periods during the last year should be unlocked partially.
            //   The number of bucket unlocks is calculated as triangular number:
            //   T(inYearDistance - 1) where -1 stands for current period.
            // - Current period is unlocked with interpolations and is subtracted from
            //   "triangular" part.
            uint32 fullDistance = currentBucket - lastAccrueBucket;
            uint32 inYearDistance = _inYearDistance(fullDistance);
            uint256 periodPart = amount / fullDistance;
            periodAddition = (periodPart * inYearDistance) / BUCKETS;

            // Payout buckets that had passed from previous accrue
            // Buckets from distance greater that year. They should be completely paid out at this time.
            if (fullDistance > BUCKETS) immediateUnlock += periodPart * (fullDistance - BUCKETS);
            // Buckets from recent year. Their area calculated using triangular number of passed buckets.
            if (fullDistance > 1) immediateUnlock += (periodPart * _triangularNumber(inYearDistance - 1)) / BUCKETS;

            for (uint32 i = 1; i <= inYearDistance; i++) {
                uint32 buck = (lastAccrueBucket + i) % BUCKETS;
                buckets[buck] += periodPart;
            }
        }

        // Unlock interpolated part of current period from newly accrued reward.
        immediateUnlock += _lerpOverPeriod(periodAddition, rightNow, _bucketTime(currentBucket, info.periodOffset));
        info.currentPeriodReward += periodAddition.toUint192();

        return immediateUnlock;
    }

    /// @dev Moves available part of delayed rewards into regular rewards
    function _unlockDelayed(address account, RewardDelayInfo memory info) internal returns (uint256) {
        uint32 rightNow = getTimestamp();
        if (info.periodOffset == 0) {
            // Init bucket offset on first accrue in protocol.
            info.periodOffset = BUCKET_DURATION - (rightNow % BUCKET_DURATION);
            // Mark block/time as paid out because we had no accruals before that.
            info.lastPayoutTime = rightNow;
        }

        // Exit if we already paid at this block or if we in initial unlock.
        if (rightNow == info.lastPayoutTime) return 0;

        uint256[BUCKETS] storage buckets = accountBuckets[account];
        (uint256 fullyUnlocked, uint256 newPeriodReward) = _calculateUnlockable(info, buckets, rightNow);

        // Clean completely paid out buckets
        uint32 currentBucket = _bucketIndex(rightNow, info.periodOffset);
        uint32 lastPayoutBucket = _bucketIndex(info.lastPayoutTime, info.periodOffset);
        uint32 fullDistance = currentBucket - lastPayoutBucket;
        uint32 inYearDistance = _inYearDistance(fullDistance);
        for (uint32 i = 1; i <= inYearDistance; i++) {
            uint32 buck = (lastPayoutBucket + i) % BUCKETS;
            buckets[buck] = 0;
        }

        // The amount of rewards in current period is used for interpolated unlock
        // and can be updated only when periods change.
        if (fullDistance > 0) {
            info.currentPeriodReward = newPeriodReward.toUint192();
        }

        info.lastPayoutTime = rightNow;

        return fullyUnlocked;
    }

    function _calculateUnlockable(
        RewardDelayInfo memory info,
        uint256[BUCKETS] storage buckets,
        uint32 rightNow
    ) internal view returns (uint256 fullyUnlocked, uint256 newPeriodReward) {
        require(rightNow >= info.lastPayoutTime, ErrorCodes.RH_PAYOUT_FROM_FUTURE);
        uint32 currentBucket = _bucketIndex(rightNow, info.periodOffset);
        uint32 lastPayoutBucket = _bucketIndex(info.lastPayoutTime, info.periodOffset);

        // Payout interpolated amount from current period
        if (currentBucket == lastPayoutBucket) {
            return (_lerpOverPeriod(info.currentPeriodReward, rightNow, info.lastPayoutTime), 0);
        }

        // Payout full buckets and get unlock rewards in this period.
        (fullyUnlocked, newPeriodReward) = _collectFullBuckets(buckets, currentBucket, lastPayoutBucket);
        // Payout unpaid interpolated reward from last period
        if (info.currentPeriodReward > 0) {
            fullyUnlocked += _lerpOverPeriod(
                info.currentPeriodReward,
                _bucketTime(lastPayoutBucket + 1, info.periodOffset),
                info.lastPayoutTime
            );
        }
        // Payout interpolated reward from new start of current period
        if (newPeriodReward > 0) {
            fullyUnlocked += _lerpOverPeriod(newPeriodReward, rightNow, _bucketTime(currentBucket, info.periodOffset));
        }
    }

    function _collectFullBuckets(
        uint256[BUCKETS] storage buckets,
        uint32 currentBucket,
        uint32 lastPayoutBucket
    ) internal view returns (uint256 fullyUnlocked, uint256 currentPeriodReward) {
        uint32 fullDistance = currentBucket - lastPayoutBucket;
        uint32 inYearDistance = _inYearDistance(fullDistance);

        // Payout the oldest buckets that should end soon including current bucket from previous iteration.
        // Start from index 2 to skip bucket next to the [lastPayoutBucket].
        for (uint32 i = 2; i <= inYearDistance; i++) {
            uint32 buck = (lastPayoutBucket + i) % BUCKETS;
            fullyUnlocked += buckets[buck] * (i - 1);
        }
        // Sum-up survived buckets to payout in the next step.
        // Each of them is paid out distance - 1 times.
        for (uint32 i = inYearDistance + 1; i <= BUCKETS; i++) {
            uint32 buck = (lastPayoutBucket + i) % BUCKETS;
            currentPeriodReward += buckets[buck];
        }
        fullyUnlocked += currentPeriodReward * (inYearDistance - 1);
        fullyUnlocked /= BUCKETS;

        // If all buckets are ended then we payout latest period with the rest
        // and zero out current period reward to disable interpolation
        currentPeriodReward = fullDistance < BUCKETS ? currentPeriodReward / BUCKETS : 0;
    }

    function _lerpOverPeriod(
        uint256 amount,
        uint32 endTime,
        uint32 startTime
    ) internal pure returns (uint256) {
        uint32 delta = (endTime - startTime);
        require(delta <= BUCKET_DURATION, ErrorCodes.RH_LERP_DELTA_IS_GREATER_THAN_PERIOD);
        return (amount * delta) / BUCKET_DURATION;
    }

    function _bucketIndex(uint32 time, uint32 periodOffset) internal pure returns (uint32) {
        return (time + periodOffset) / BUCKET_DURATION;
    }

    function _bucketTime(uint32 bucketIndex, uint32 periodOffset) internal pure returns (uint32) {
        return bucketIndex * BUCKET_DURATION - periodOffset;
    }

    function _triangularNumber(uint32 n) internal pure returns (uint32) {
        return (n * n + n) / 2;
    }

    function _inYearDistance(uint32 fullDistance) internal pure returns (uint32) {
        return fullDistance < BUCKETS ? fullDistance : BUCKETS;
    }

    function _marketSource(IMToken market, bool isSupply) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(address(market), isSupply));
    }

    // // // // Withdrawal

    /// @inheritdoc IRewardsHub
    function withdraw(uint256 amount) external checkPaused(WITHDRAW_OP) {
        RewardDelayInfo memory info = delayInfos[msg.sender];
        uint256 unlocked = _unlockDelayed(msg.sender, info);
        delayInfos[msg.sender] = info; // always update
        if (unlocked > 0) {
            balances[msg.sender] += unlocked;
            emit RewardUnlocked(msg.sender, unlocked);
        }

        if (amount > 0) {
            uint256 balance = balances[msg.sender];
            if (amount == type(uint256).max) amount = balance;
            require(amount <= balance, ErrorCodes.INCORRECT_AMOUNT);

            balances[msg.sender] = balance - amount;
            emit Withdraw(msg.sender, amount);

            mnt.safeTransfer(msg.sender, amount);
        }

        if (unlocked > 0 || amount > 0) {
            buyback().updateBuybackAndVotingWeights(msg.sender);
        }
    }

    /// @inheritdoc IRewardsHub
    function grant(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, ErrorCodes.INCORRECT_AMOUNT);

        uint256 balance = mnt.balanceOf(address(this));
        require(balance >= amount, ErrorCodes.INSUFFICIENT_MNT_FOR_GRANT);

        emit MntGranted(recipient, amount);

        mnt.safeTransfer(recipient, amount);
    }

    // // // // Admin zone

    /// @inheritdoc IRewardsHub
    function setMntEmissionRates(
        IMToken mToken,
        uint256 newMntSupplyEmissionRate,
        uint256 newMntBorrowEmissionRate
    ) external onlyRole(TIMELOCK) {
        require(supervisor().isMarketListed(mToken), ErrorCodes.MARKET_NOT_LISTED);

        if (mntSupplyEmissionRate[mToken] != newMntSupplyEmissionRate) {
            // Supply emission rate updated so let's update supply state to ensure that
            //  1. MNT accrued properly for the old emission rate.
            //  2. MNT accrued at the new speed starts after this block.
            updateMntSupplyIndex(mToken);

            // Update emission rate and emit event
            mntSupplyEmissionRate[mToken] = newMntSupplyEmissionRate;
            emit MntSupplyEmissionRateUpdated(mToken, newMntSupplyEmissionRate);
        }

        if (mntBorrowEmissionRate[mToken] != newMntBorrowEmissionRate) {
            // Borrow emission rate updated so let's update borrow state to ensure that
            //  1. MNT accrued properly for the old emission rate.
            //  2. MNT accrued at the new speed starts after this block.
            uint224 borrowIndex = mToken.borrowIndex().toUint224();
            updateMntBorrowIndex(mToken, borrowIndex);

            // Update emission rate and emit event
            mntBorrowEmissionRate[mToken] = newMntBorrowEmissionRate;
            emit MntBorrowEmissionRateUpdated(mToken, newMntBorrowEmissionRate);
        }
    }

    // // // // Pause control

    bytes32 internal constant DISTRIBUTION_OP = "MntDistribution";
    bytes32 internal constant WITHDRAW_OP = "Withdraw";

    function validatePause(address) internal view override {
        require(hasRole(GATEKEEPER, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    function validateUnpause(address) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    // // // // Utils

    function getTimestamp() internal view virtual returns (uint32) {
        return block.timestamp.toUint32();
    }

    function getBlockNumber() internal view virtual returns (uint32) {
        return block.number.toUint32();
    }

    function supervisor() internal view returns (ISupervisor) {
        return getInterconnector().supervisor();
    }

    function buyback() internal view returns (IBuyback) {
        return getInterconnector().buyback();
    }
}