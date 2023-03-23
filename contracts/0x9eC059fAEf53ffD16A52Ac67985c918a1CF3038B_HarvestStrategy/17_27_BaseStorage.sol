// SPDX-License-Identifier: BUSL-1.1

import "../interfaces/ISwapData.sol";

pragma solidity 0.8.11;

/// @notice Strategy struct for all strategies
struct Strategy {
    uint128 totalShares;

    /// @notice Denotes strategy completed index
    uint24 index;

    /// @notice Denotes whether strategy is removed
    /// @dev after removing this value can never change, hence strategy cannot be added back again
    bool isRemoved;

    /// @notice Pending geposit amount and pending shares withdrawn by all users for next index 
    Pending pendingUser;

    /// @notice Used if strategies "dohardwork" hasn't been executed yet in the current index
    Pending pendingUserNext;

    /// @dev Usually a temp variable when compounding
    mapping(address => uint256) pendingRewards;

    /// @notice Amount of lp tokens the strategy holds, NOTE: not all strategies use it
    uint256 lpTokens;

    /// @dev Usually a temp variable when compounding
    uint128 pendingDepositReward;

    // ----- REALLOCATION VARIABLES -----

    bool isInDepositPhase;

    /// @notice Used to store amount of optimized shares, so they can be substracted at the end
    /// @dev Only for temporary use, should be reset to 0 in same transaction
    uint128 optimizedSharesWithdrawn;

    /// @dev Underlying amount pending to be deposited from other strategies at reallocation 
    /// @dev Actual amount needed to be deposited and was withdrawn from others for reallocation
    /// @dev resets after the strategy reallocation DHW is finished
    uint128 pendingReallocateDeposit;

    /// @notice Stores amount of optimized underlying amount when reallocating
    /// @dev resets after the strategy reallocation DHW is finished
    /// @dev This is "virtual" amount that was matched between this strategy and others when reallocating
    uint128 pendingReallocateOptimizedDeposit;

    /// @notice Average oprimized and non-optimized deposit
    /// @dev Deposit from all strategies by taking the average of optimizedna dn non-optimized deposit
    /// @dev Used as reallocation deposit recieved
    uint128 pendingReallocateAverageDeposit;

    // ------------------------------------

    /// @notice Total underlying amoung at index
    mapping(uint256 => TotalUnderlying) totalUnderlying;

    /// @notice Batches stored after each DHW with index as a key
    /// @dev Holds information for vauls to redeem newly gained shares and withdrawn amounts belonging to users
    mapping(uint256 => Batch) batches;

    /// @notice Batches stored after each DHW reallocating (if strategy was set to reallocate)
    /// @dev Holds information for vauls to redeem newly gained shares and withdrawn shares to complete reallocation
    mapping(uint256 => BatchReallocation) reallocationBatches;

    /// @notice Vaults holding this strategy shares
    mapping(address => Vault) vaults;

    /// @notice Future proof storage
    mapping(bytes32 => AdditionalStorage) additionalStorage;

    /// @dev Make sure to reset it to 0 after emergency withdrawal
    uint256 emergencyPending;
}

/// @notice Unprocessed deposit underlying amount and strategy share amount from users
struct Pending {
    uint128 deposit;
    uint128 sharesToWithdraw;
}

/// @notice Struct storing total underlying balance of a strategy for an index, along with total shares at same index
struct TotalUnderlying {
    uint128 amount;
    uint128 totalShares;
}

/// @notice Stored after executing DHW for each index.
/// @dev This is used for vaults to redeem their deposit.
struct Batch {
    /// @notice total underlying deposited in index
    uint128 deposited;
    uint128 depositedReceived;
    uint128 depositedSharesReceived;
    uint128 withdrawnShares;
    uint128 withdrawnReceived;
}

/// @notice Stored after executing reallocation DHW each index.
struct BatchReallocation {
    /// @notice Deposited amount received from reallocation
    uint128 depositedReallocation;

    /// @notice Received shares from reallocation
    uint128 depositedReallocationSharesReceived;

    /// @notice Used to know how much tokens was received for reallocating
    uint128 withdrawnReallocationReceived;

    /// @notice Amount of shares to withdraw for reallocation
    uint128 withdrawnReallocationShares;
}

/// @notice VaultBatches could be refactored so we only have 2 structs current and next (see how Pending is working)
struct Vault {
    uint128 shares;

    /// @notice Withdrawn amount as part of the reallocation
    uint128 withdrawnReallocationShares;

    /// @notice Index to action
    mapping(uint256 => VaultBatch) vaultBatches;
}

/// @notice Stores deposited and withdrawn shares by the vault
struct VaultBatch {
    /// @notice Vault index to deposited amount mapping
    uint128 deposited;

    /// @notice Vault index to withdrawn user shares mapping
    uint128 withdrawnShares;
}

/// @notice Used for reallocation calldata
struct VaultData {
    address vault;
    uint8 strategiesCount;
    uint256 strategiesBitwise;
    uint256 newProportions;
}

/// @notice Calldata when executing reallocatin DHW
/// @notice Used in the withdraw part of the reallocation DHW
struct ReallocationWithdrawData {
    uint256[][] reallocationTable;
    StratUnderlyingSlippage[] priceSlippages;
    RewardSlippages[] rewardSlippages;
    uint256[] stratIndexes;
    uint256[][] slippages;
}

/// @notice Calldata when executing reallocatin DHW
/// @notice Used in the deposit part of the reallocation DHW
struct ReallocationData {
    uint256[] stratIndexes;
    uint256[][] slippages;
}

/// @notice In case some adapters need extra storage
struct AdditionalStorage {
    uint256 value;
    address addressValue;
    uint96 value96;
}

/// @notice Strategy total underlying slippage, to verify validity of the strategy state
struct StratUnderlyingSlippage {
    uint256 min;
    uint256 max;
}

/// @notice Containig information if and how to swap strategy rewards at the DHW
/// @dev Passed in by the do-hard-worker
struct RewardSlippages {
    bool doClaim;
    SwapData[] swapData;
}

/// @notice Helper struct to compare strategy share between eachother
/// @dev Used for reallocation optimization of shares (strategy matching deposits and withdrawals between eachother when reallocating)
struct PriceData {
    uint256 totalValue;
    uint256 totalShares;
}

/// @notice Strategy reallocation values after reallocation optimization of shares was calculated 
struct ReallocationShares {
    uint128[] optimizedWithdraws;
    uint128[] optimizedShares;
    uint128[] totalSharesWithdrawn;
    uint256[][] optimizedReallocationTable;
}

/// @notice Shared storage for multiple strategies
/// @dev This is used when strategies are part of the same proticil (e.g. Curve 3pool)
struct StrategiesShared {
    uint184 value;
    uint32 lastClaimBlock;
    uint32 lastUpdateBlock;
    uint8 stratsCount;
    mapping(uint256 => address) stratAddresses;
    mapping(bytes32 => uint256) bytesValues;
}

/// @notice Base storage shared betweek Spool contract and Strategies
/// @dev this way we can use same values when performing delegate call
/// to strategy implementations from the Spool contract
abstract contract BaseStorage {
    // ----- DHW VARIABLES -----

    /// @notice Force while DHW (all strategies) to be executed in only one transaction
    /// @dev This is enforced to increase the gas efficiency of the system
    /// Can be removed by the DAO if gas gost of the strategies goes over the block limit
    bool internal forceOneTxDoHardWork;

    /// @notice Global index of the system
    /// @dev Insures the correct strategy DHW execution.
    /// Every strategy in the system must be equal or one less than global index value
    /// Global index increments by 1 on every do-hard-work
    uint24 public globalIndex;

    /// @notice number of strategies unprocessed (by the do-hard-work) in the current index to be completed
    uint8 internal doHardWorksLeft;

    // ----- REALLOCATION VARIABLES -----

    /// @notice Used for offchain execution to get the new reallocation table.
    bool internal logReallocationTable;

    /// @notice number of withdrawal strategies unprocessed (by the do-hard-work) in the current index
    /// @dev only used when reallocating
    /// after it reaches 0, deposit phase of the reallocation can begin
    uint8 public withdrawalDoHardWorksLeft;

    /// @notice Index at which next reallocation is set
    uint24 public reallocationIndex;

    /// @notice 2D table hash containing information of how strategies should be reallocated between eachother
    /// @dev Created when allocation provider sets reallocation for the vaults
    /// This table is stored as a hash in the system and verified on reallocation DHW
    /// Resets to 0 after reallocation DHW is completed
    bytes32 internal reallocationTableHash;

    /// @notice Hash of all the strategies array in the system at the time when reallocation was set for index
    /// @dev this array is used for the whole reallocation period even if a strategy gets exploited when reallocating.
    /// This way we can remove the strategy from the system and not breaking the flow of the reallocaton
    /// Resets when DHW is completed
    bytes32 internal reallocationStrategiesHash;

    // -----------------------------------

    /// @notice Denoting if an address is the do-hard-worker
    mapping(address => bool) public isDoHardWorker;

    /// @notice Denoting if an address is the allocation provider
    mapping(address => bool) public isAllocationProvider;

    /// @notice Strategies shared storage
    /// @dev used as a helper storage to save common inoramation
    mapping(bytes32 => StrategiesShared) internal strategiesShared;

    /// @notice Mapping of strategy implementation address to strategy system values
    mapping(address => Strategy) public strategies;

    /// @notice Flag showing if disable was skipped when a strategy has been removed
    /// @dev If true disable can still be run 
    mapping(address => bool) internal _skippedDisable;

    /// @notice Flag showing if after removing a strategy emergency withdraw can still be executed
    /// @dev If true emergency withdraw can still be executed
    mapping(address => bool) internal _awaitingEmergencyWithdraw;
}