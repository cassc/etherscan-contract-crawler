// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IEmissionBooster.sol";
import "./libraries/ErrorCodes.sol";
import "./InterconnectorLeaf.sol";

contract EmissionBooster is IEmissionBooster, Initializable, AccessControl, ReentrancyGuard, InterconnectorLeaf {
    /**
     * @dev Contains end block of checkpoint and what tiers where active during it
     */
    struct TierCheckpoint {
        uint32 startBlock;
        uint224 activeTiers;
    }

    struct TierData {
        // Block number in which the emission boost starts work. This block number is stored at the moment
        // the category is activated.
        uint32 startBlock;
        // Block number in which the emission boost ends.
        uint32 endBlock;
        // Emissions Boost for MNT Emissions Rewards, scaled by 1e18
        uint256 emissionBoost;
    }

    /// @dev Based on bitmap size used in TierCheckpoint
    uint256 internal constant MAX_TIERS = 224;

    /// @notice Address of the Minterest NFT.
    address public minterestNFT;

    /// @dev The Tier for each MinterestNFT token
    mapping(uint256 => uint256) public tokenTier;

    /// @dev Bitmap with accounts tiers
    mapping(address => uint256) internal accountToTiers;

    /// @dev Stores how much tokens of one tier account have
    mapping(address => mapping(uint256 => uint256)) internal accountToTierAmounts;

    /// @notice A list of all created Tiers
    TierData[] public tiers;

    /// @dev A list of checkpoints of tiers
    TierCheckpoint[] internal checkpoints;

    /// @notice Indicates whether the emission boost mode is enabled.
    /// If enabled - we perform calculations of the emission boost for MNT distribution,
    /// if disabled - additional calculations are not performed. This flag can only be activated once.
    bool public isEmissionBoostingEnabled;

    /// @dev Indicates the Tier that should be updated next in a specific market.
    mapping(IMToken => uint256) internal tierToBeUpdatedSupplyIndex;
    mapping(IMToken => uint256) internal tierToBeUpdatedBorrowIndex;

    /// @notice Stores markets indexes per block.
    mapping(IMToken => mapping(uint256 => uint256)) public marketSupplyIndexes;
    mapping(IMToken => mapping(uint256 => uint256)) public marketBorrowIndexes;

    constructor() {
        _disableInitializers();
    }

    /**
     * @param admin_ Address of the Admin
     * @param minterestNFT_ Address of the Minterest NFT contract
     */
    function initialize(address admin_, address minterestNFT_) external initializer {
        require(admin_ != address(0), ErrorCodes.ADMIN_ADDRESS_CANNOT_BE_ZERO);
        require(minterestNFT_ != address(0), ErrorCodes.TOKEN_ADDRESS_CANNOT_BE_ZERO);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        minterestNFT = minterestNFT_;

        // Create zero Tier. Zero Tier is always disabled.
        tiers.push(TierData({startBlock: 0, endBlock: 0, emissionBoost: 0}));
    }

    //// NFT callback functions ////

    /// @inheritdoc IEmissionBooster
    function onMintToken(
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        uint256[] memory tiers_
    ) external {
        require(msg.sender == minterestNFT, ErrorCodes.UNAUTHORIZED);

        uint256 transferredTiers = 0;
        for (uint256 i = 0; i < ids_.length; i++) {
            uint256 tier = tiers_[i];
            if (tier == 0) continue; // Process only positive tiers

            require(tierExists(tier), ErrorCodes.EB_TIER_DOES_NOT_EXIST);
            require(!isTierActive(tier), ErrorCodes.EB_CANNOT_MINT_TOKEN_FOR_ACTIVATED_TIER);

            tokenTier[ids_[i]] = tier;
            accountToTierAmounts[to_][tier] += amounts_[i];
            transferredTiers |= _tierMask(tier);
        }

        // Update only if receiver has got new tiers
        uint256 tiersDiff = accountToTiers[to_] ^ transferredTiers;
        if (tiersDiff > 0) {
            // slither-disable-next-line reentrancy-no-eth
            rewardsHub().distributeAllMnt(to_);
            accountToTiers[to_] |= transferredTiers;
        }
    }

    /// @inheritdoc IEmissionBooster
    function onTransferToken(
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    ) external {
        require(msg.sender == minterestNFT, ErrorCodes.UNAUTHORIZED);

        uint256 removedTiers = 0;
        uint256 transferredTiers = 0;
        IRewardsHub cachedRewardsHub = rewardsHub();

        for (uint256 i = 0; i < ids_.length; i++) {
            (uint256 id, uint256 amount) = (ids_[i], amounts_[i]);
            if (amount == 0) continue;

            uint256 tier = tokenTier[id];
            if (tier == 0) continue;

            uint256 mask = _tierMask(tier);
            transferredTiers |= mask;

            accountToTierAmounts[from_][tier] -= amount;
            if (accountToTierAmounts[from_][tier] == 0) removedTiers |= mask;

            accountToTierAmounts[to_][tier] += amount;
        }

        // Update only if sender has removed tiers
        if (removedTiers > 0) {
            // slither-disable-next-line reentrancy-no-eth,reentrancy-benign
            cachedRewardsHub.distributeAllMnt(from_);
            accountToTiers[from_] &= ~removedTiers;
        }

        // Update only if receiver has got new tiers
        uint256 tiersDiff = accountToTiers[to_] ^ transferredTiers;
        if (tiersDiff > 0) {
            // slither-disable-next-line reentrancy-no-eth
            cachedRewardsHub.distributeAllMnt(to_);
            accountToTiers[to_] |= transferredTiers;
        }
    }

    //// Admin Functions ////

    /// @inheritdoc IEmissionBooster
    function enableEmissionBoosting() external {
        IWhitelist whitelist = getInterconnector().whitelist();

        require(msg.sender == address(whitelist), ErrorCodes.UNAUTHORIZED);
        isEmissionBoostingEnabled = true;
        // we do not activate the zero tier
        uint256[] memory tiersForEnabling = new uint256[](tiers.length - 1);
        for (uint256 i = 0; i < tiersForEnabling.length; i++) {
            tiersForEnabling[i] = i + 1;
        }

        enableTiersInternal(tiersForEnabling);
        emit EmissionBoostEnabled(msg.sender);
    }

    /// @inheritdoc IEmissionBooster
    function createTiers(uint32[] memory endBoostBlocks, uint256[] memory emissionBoosts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(endBoostBlocks.length == emissionBoosts.length, ErrorCodes.INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL);
        require(
            tiers.length + endBoostBlocks.length - 1 <= MAX_TIERS, // Subtract zero tier
            ErrorCodes.EB_TIER_LIMIT_REACHED
        );

        for (uint256 i = 0; i < endBoostBlocks.length; i++) {
            uint32 end = endBoostBlocks[i];
            uint256 boost = emissionBoosts[i];

            require(_getBlockNumber() < end, ErrorCodes.EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT);
            require(boost > 0 && boost <= 0.5e18, ErrorCodes.EB_EMISSION_BOOST_IS_NOT_IN_RANGE);

            tiers.push(TierData({startBlock: 0, endBlock: end, emissionBoost: boost}));
            emit NewTierCreated(tiers.length - 1, end, boost);
        }
    }

    /// @inheritdoc IEmissionBooster
    function enableTiers(uint256[] memory tiersForEnabling) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        enableTiersInternal(tiersForEnabling);
    }

    /// @notice Enables emission boost in specified Tiers
    /// @param tiersForEnabling Tier for enabling emission boost
    function enableTiersInternal(uint256[] memory tiersForEnabling) internal {
        uint32 currentBlock = uint32(_getBlockNumber());

        // For each tier of tiersForEnabling set startBlock
        for (uint256 i = 0; i < tiersForEnabling.length; i++) {
            uint256 tier = tiersForEnabling[i];
            require(tier != 0, ErrorCodes.EB_ZERO_TIER_CANNOT_BE_ENABLED);
            require(tierExists(tier), ErrorCodes.EB_TIER_DOES_NOT_EXIST);
            require(!isTierActive(tier), ErrorCodes.EB_ALREADY_ACTIVATED_TIER);
            require(currentBlock < tiers[tier].endBlock, ErrorCodes.EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT);
            tiers[tier].startBlock = currentBlock;
        }

        _rebuildCheckpoints();

        // For all markets update mntSupplyIndex and mntBorrowIndex, and set marketSpecificData index
        IMToken[] memory markets = supervisor().getAllMarkets();
        IRewardsHub cachedRewardsHub = rewardsHub();

        for (uint256 i = 0; i < markets.length; i++) {
            IMToken market = markets[i];
            tierToBeUpdatedSupplyIndex[market] = getNextTierToBeUpdatedIndex(market, true);
            tierToBeUpdatedBorrowIndex[market] = getNextTierToBeUpdatedIndex(market, false);
            // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
            (uint224 mntSupplyIndex, uint224 mntBorrowIndex) = cachedRewardsHub.updateAndGetMntIndexes(market);
            marketSupplyIndexes[market][currentBlock] = mntSupplyIndex;
            marketBorrowIndexes[market][currentBlock] = mntBorrowIndex;
            for (uint256 index = 0; index < tiersForEnabling.length; index++) {
                uint256 tier = tiersForEnabling[index];
                emit TierEnabled(market, tier, currentBlock, mntSupplyIndex, mntBorrowIndex);
            }
        }
    }

    /// @dev Rebuilds tier checkpoints array from scratch.
    /// Checkpoints have end block and bitmap with active tiers.
    /// Final checkpoint has the same block as previous but empty bitmap.
    ///           10     20     30     40     50     50
    ///     _0001_|_0011_|_1111_|_0101_|_0001_|_0000_|
    function _rebuildCheckpoints() internal {
        TierData[] memory tiers_ = tiers;

        // Find bounds of all tiers
        uint256 firstStartBlock = type(uint256).max;
        uint256 lastEndBlock = type(uint256).min;
        for (uint256 tier = 1; tier < tiers_.length; tier++) {
            uint256 tierStart = tiers_[tier].startBlock;
            if (tierStart == 0) continue; // Skip disabled tiers

            uint256 tierEnd = tiers_[tier].endBlock;
            if (tierStart < firstStartBlock) firstStartBlock = tierStart;
            if (tierEnd > lastEndBlock) lastEndBlock = tierEnd;
        }

        // Build checkpoints...
        uint256 checkpointsLen = checkpoints.length;
        uint256 checkpointsIdx = 0; // First zero checkpoint
        uint256 currStartBlock = firstStartBlock;

        // Add empty checkpoint at the start
        // Used to close first tier in boost calculation
        if (checkpointsIdx < checkpointsLen) {
            checkpoints[checkpointsIdx] = TierCheckpoint(0, 0);
            checkpointsIdx++;
        } else {
            checkpoints.push(TierCheckpoint(0, 0));
        }

        while (currStartBlock < lastEndBlock) {
            uint256 nextChangeBlock = type(uint256).max;
            uint256 activeTiers = 0;

            for (uint256 tier = 1; tier < tiers_.length; tier++) {
                uint256 tierStart = tiers_[tier].startBlock;
                if (tierStart == 0) continue; // Skip disabled tiers

                uint256 tierEnd = tiers_[tier].endBlock;

                // Find next tier state change
                if (tierStart > currStartBlock && tierStart < nextChangeBlock) nextChangeBlock = tierStart;
                if (tierEnd > currStartBlock && tierEnd < nextChangeBlock) nextChangeBlock = tierEnd;

                // If tier starts now and ends later - it's active
                if (tierStart <= currStartBlock && tierEnd > currStartBlock) activeTiers |= _tierMask(tier);
            }

            // Overwrite old checkpoint or push new one
            if (checkpointsIdx < checkpointsLen) {
                checkpoints[checkpointsIdx] = TierCheckpoint(uint32(currStartBlock), uint224(activeTiers));
                checkpointsIdx++;
            } else {
                checkpoints.push(TierCheckpoint(uint32(currStartBlock), uint224(activeTiers)));
            }

            currStartBlock = nextChangeBlock;
        }

        // Add empty checkpoint at the end
        // Used to close final tier in boost calculation
        if (checkpointsIdx < checkpointsLen) {
            checkpoints[checkpointsIdx] = TierCheckpoint(uint32(lastEndBlock), 0);
        } else {
            checkpoints.push(TierCheckpoint(uint32(lastEndBlock), 0));
        }
    }

    /*** Helper special functions ***/

    /// @inheritdoc IEmissionBooster
    function getNumberOfTiers() external view returns (uint256) {
        return tiers.length;
    }

    /// @dev Function to simply retrieve block number
    ///      This exists mainly for inheriting test contracts to stub this result.
    function _getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    /// @inheritdoc IEmissionBooster
    function isTierActive(uint256 tier_) public view returns (bool) {
        return tiers[tier_].startBlock > 0;
    }

    /// @inheritdoc IEmissionBooster
    function tierExists(uint256 tier_) public view returns (bool) {
        return tier_ < tiers.length;
    }

    /// @inheritdoc IEmissionBooster
    function getAccountTiersBitmap(address account_) external view returns (uint256) {
        return accountToTiers[account_];
    }

    /// @inheritdoc IEmissionBooster
    function isAccountHaveTiers(address account_) public view returns (bool) {
        return accountToTiers[account_] > 0;
    }

    /// @inheritdoc IEmissionBooster
    function getCurrentAccountBoost(address account_) external view returns (uint256 tier, uint256 boost) {
        uint256 active = accountToTiers[account_];
        uint256 blockN = _getBlockNumber();
        // We shift `active` and use it as condition to continue loop.
        for (uint256 ti = 1; active > 0; ti++) {
            if (active & 1 == 1) {
                TierData storage tr = tiers[ti];
                if (tr.emissionBoost > boost && tr.startBlock <= blockN && blockN < tr.endBlock) {
                    tier = ti;
                    boost = tr.emissionBoost;
                }
            }
            active >>= 1;
        }
    }

    struct CalcEmissionVars {
        uint256 currentBlock;
        uint256 accountTiers;
        uint256 highIndex;
        uint256 prevBoost;
        uint256 prevCpIndex;
    }

    /// @inheritdoc IEmissionBooster
    function calculateEmissionBoost(
        IMToken market_,
        address account_,
        uint256 userLastIndex_,
        uint256 userLastBlock_,
        uint256 marketIndex_,
        bool isSupply_
    ) public view virtual returns (uint256 boostedIndex) {
        require(marketIndex_ >= userLastIndex_, ErrorCodes.EB_MARKET_INDEX_IS_LESS_THAN_USER_INDEX);
        require(userLastIndex_ >= 1e36, ErrorCodes.EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL);

        // If emission boosting is disabled or account doesn't have NFT return nothing
        if (!isEmissionBoostingEnabled || !isAccountHaveTiers(account_)) {
            return 0;
        }

        // User processed every checkpoint and can't receive any boosts because they are ended.
        if (userLastBlock_ > checkpoints[checkpoints.length - 1].startBlock) {
            return 0;
        }

        // Thesaurus:
        //   Checkpoint, CP - Marks the end of the period and what tiers where active during it.
        //   Segment - Interval with the same boost amount.
        //   Low index, LI - Starting index of the segment.
        //   High index, HI - Ending index of the segment.

        CalcEmissionVars memory vars = CalcEmissionVars({
            currentBlock: _getBlockNumber(),
            accountTiers: accountToTiers[account_],
            highIndex: 0,
            prevBoost: 0,
            prevCpIndex: 0
        });

        // Remember, we are iterating in reverse: from recent checkpoints to the old ones.
        for (uint256 cpi = checkpoints.length; cpi > 0; cpi--) {
            TierCheckpoint memory cp = checkpoints[cpi - 1];

            // Skip if this checkpoint is not started yet
            if (cp.startBlock >= vars.currentBlock) continue;

            uint256 active = uint256(cp.activeTiers) & vars.accountTiers;
            uint256 cpIndex = isSupply_
                ? marketSupplyIndexes[market_][cp.startBlock]
                : marketBorrowIndexes[market_][cp.startBlock];

            if (active == 0) {
                // No active tiers in this checkpoint.

                if (vars.prevBoost > 0) {
                    // Payout - Tier start
                    // Prev tier started after we had no active tiers in this CP.

                    uint256 deltaIndex = vars.highIndex - vars.prevCpIndex;
                    boostedIndex += (deltaIndex * vars.prevBoost) / 1e18;

                    // No active tiers in this checkpoint, so we zero out values.
                    vars.highIndex = 0;
                    vars.prevBoost = 0;
                }

                // We reached checkpoint that was active last time and can exit.
                if (cp.startBlock <= userLastBlock_) break;

                vars.prevCpIndex = cpIndex;
                continue;
            }

            uint256 highestBoost = _findHighestTier(active);

            if (vars.prevBoost == highestBoost && cp.startBlock >= userLastBlock_) {
                vars.prevCpIndex = cpIndex;
                continue;
            }

            if (vars.prevBoost == 0) {
                // If there was no previous tier then we starting new segment.

                // When we are processing first (last in time) started checkpoint we have no prevCpIndex.
                // In that case we should use marketIndex_ and prevCpIndex otherwise.
                vars.highIndex = vars.prevCpIndex > 0 ? vars.prevCpIndex : marketIndex_;
            } else if (vars.prevBoost != highestBoost) {
                // Payout - Change tier
                // In this checkpoint is active other tier than in previous one.

                uint256 deltaIndex = vars.highIndex - vars.prevCpIndex;
                boostedIndex += (deltaIndex * vars.prevBoost) / 1e18;

                // Remember lowest index of previous segment as the highest index of new segment.
                vars.highIndex = vars.prevCpIndex;
            }

            if (cp.startBlock <= userLastBlock_) {
                // Payout - Deep break
                // We reached checkpoint that was active last time.
                // Since this is active tier we can use user index as LI.

                uint256 deltaIndex = vars.highIndex - userLastIndex_;
                boostedIndex += (deltaIndex * highestBoost) / 1e18;

                break;
            }

            // Save data about current checkpoint
            vars.prevBoost = highestBoost;
            vars.prevCpIndex = cpIndex;
        }
    }

    /// @dev Finds tier with highest boost value from supplied bitmap
    /// @param active Set of tiers in form of bitmap to find the highest tier from
    /// @return highestBoost Highest tier boost amount with subtracted 1e18
    function _findHighestTier(uint256 active) internal view returns (uint256 highestBoost) {
        // We shift `active` and use it as condition to continue loop.
        for (uint256 ti = 1; active > 0; ti++) {
            if (active & 1 == 1) {
                uint256 tierEmissionBoost = tiers[ti].emissionBoost;
                if (tierEmissionBoost > highestBoost) {
                    highestBoost = tierEmissionBoost;
                }
            }
            active >>= 1;
        }
    }

    /// @inheritdoc IEmissionBooster
    function updateSupplyIndexesHistory(
        IMToken market,
        uint256 lastUpdatedBlock,
        uint256 lastUpdatedIndex,
        uint256 currentSupplyIndex
    ) public virtual {
        require(msg.sender == address(rewardsHub()), ErrorCodes.UNAUTHORIZED);
        require(
            currentSupplyIndex >= 1e36 && lastUpdatedIndex >= 1e36,
            ErrorCodes.EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL
        );

        uint256 nextTier = tierToBeUpdatedSupplyIndex[market];
        // If parameter nextTier is equal to zero, it means that all Tiers have already been updated.
        if (nextTier == 0) return;

        uint256 currentBlock = _getBlockNumber();
        uint256 endBlock = tiers[nextTier].endBlock;
        uint256 period = currentBlock - lastUpdatedBlock;

        // calculate and fill all expired markets that were not updated
        // we expect that there will be only one expired tier at a time, but will parse all just in case
        while (endBlock <= currentBlock) {
            if (isTierActive(nextTier) && (marketSupplyIndexes[market][endBlock] == 0)) {
                uint224 newIndex = uint224(
                    lastUpdatedIndex +
                        (((currentSupplyIndex - lastUpdatedIndex) * (endBlock - lastUpdatedBlock)) / period)
                );

                marketSupplyIndexes[market][endBlock] = newIndex;

                emit SupplyIndexUpdated(address(market), nextTier, newIndex, uint32(endBlock));
            }

            nextTier = getNextTierToBeUpdatedIndex(market, true);
            tierToBeUpdatedSupplyIndex[market] = nextTier;

            if (nextTier == 0) break;

            endBlock = tiers[nextTier].endBlock;
        }
    }

    /// @inheritdoc IEmissionBooster
    function updateBorrowIndexesHistory(
        IMToken market,
        uint256 lastUpdatedBlock,
        uint256 lastUpdatedIndex,
        uint256 currentBorrowIndex
    ) public virtual {
        require(msg.sender == address(rewardsHub()), ErrorCodes.UNAUTHORIZED);
        require(
            currentBorrowIndex >= 1e36 && lastUpdatedIndex >= 1e36,
            ErrorCodes.EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL
        );

        uint256 nextTier = tierToBeUpdatedBorrowIndex[market];
        // If parameter nextTier is equal to zero, it means that all Tiers have already been updated.
        if (nextTier == 0) return;

        uint256 currentBlock = _getBlockNumber();
        uint256 endBlock = tiers[nextTier].endBlock;
        uint256 period = currentBlock - lastUpdatedBlock;

        // calculate and fill all expired markets that were not updated
        while (endBlock <= currentBlock) {
            if (isTierActive(nextTier) && (marketBorrowIndexes[market][endBlock] == 0)) {
                uint224 newIndex = uint224(
                    lastUpdatedIndex +
                        (((currentBorrowIndex - lastUpdatedIndex) * (endBlock - lastUpdatedBlock)) / period)
                );

                marketBorrowIndexes[market][endBlock] = newIndex;

                emit BorrowIndexUpdated(address(market), nextTier, newIndex, uint32(endBlock));
            }

            nextTier = getNextTierToBeUpdatedIndex(market, false);
            tierToBeUpdatedBorrowIndex[market] = nextTier;

            if (nextTier == 0) break;

            endBlock = tiers[nextTier].endBlock;
        }
    }

    /// @inheritdoc IEmissionBooster
    function getNextTierToBeUpdatedIndex(IMToken market, bool isSupply_) public view returns (uint256) {
        // Find the next Tier that should be updated. We are skipping Zero Tier.
        uint256 numberOfBoostingTiers = tiers.length - 1;

        // return zero if no next tier available
        if (numberOfBoostingTiers < 1) return 0;

        // set closest tier to update to be tier 1
        // we expect this list to be ordered but we have to check anyway
        uint256 closest = 0;
        uint256 bestTier = 0;

        for (uint256 tier = 1; tier <= numberOfBoostingTiers; tier++) {
            // skip non-started tiers
            if (!isTierActive(tier)) continue;

            // skip any finalized market
            uint256 current = tiers[tier].endBlock;
            if (isSupply_) {
                if (marketSupplyIndexes[market][current] != 0) continue;
            } else {
                if (marketBorrowIndexes[market][current] != 0) continue;
            }

            // init closest with the first non-passed yet tier
            if (closest == 0) {
                closest = current;
                bestTier = tier;
                continue;
            }

            // we are here if potentially closest tier is found, performing final check
            if (current < closest) {
                closest = current;
                bestTier = tier;
            }
        }

        return bestTier;
    }

    function _tierMask(uint256 tier) internal pure returns (uint256) {
        return tier > 0 ? 1 << (tier - 1) : 0;
    }

    function rewardsHub() internal view returns (IRewardsHub) {
        return getInterconnector().rewardsHub();
    }

    function supervisor() internal view returns (ISupervisor) {
        return getInterconnector().supervisor();
    }
}