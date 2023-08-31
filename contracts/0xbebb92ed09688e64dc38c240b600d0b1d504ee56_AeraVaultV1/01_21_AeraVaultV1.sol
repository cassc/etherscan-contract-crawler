// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/Math.sol";
import "./dependencies/openzeppelin/ERC165Checker.sol";
import "./interfaces/IBManagedPoolFactory.sol";
import "./interfaces/IBManagedPoolController.sol";
import "./interfaces/IBMerkleOrchard.sol";
import "./interfaces/IBVault.sol";
import "./interfaces/IBManagedPool.sol";
import "./interfaces/IAeraVaultV1.sol";
import "./interfaces/IWithdrawalValidator.sol";

/// @title Risk-managed treasury vault.
/// @notice Managed n-asset vault that supports withdrawals
///         in line with a pre-defined validator contract.
/// @dev Vault owner is the asset owner.
contract AeraVaultV1 is IAeraVaultV1, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// STORAGE ///

    uint256 internal constant ONE = 10**18;

    /// @notice Minimum period for weight change duration.
    uint256 private constant MINIMUM_WEIGHT_CHANGE_DURATION = 4 hours;

    /// @notice Maximum absolute change in swap fee.
    uint256 private constant MAXIMUM_SWAP_FEE_PERCENT_CHANGE = 0.005e18;

    /// @dev Address to represent unset guardian in events.
    address private constant UNSET_GUARDIAN_ADDRESS = address(0);

    /// @notice Largest possible notice period for vault termination (2 months).
    uint256 private constant MAX_NOTICE_PERIOD = 60 days;

    /// @notice Cooldown period for updating swap fee (1 minute).
    uint256 private constant SWAP_FEE_COOLDOWN_PERIOD = 1 minutes;

    /// @notice Largest possible weight change ratio per one second.
    /// @dev It's the increment/decrement factor per one second.
    ///      increment/decrement factor per n seconds: Fn = f * n
    ///      Weight growth range for n seconds: [1 / Fn - 1, Fn - 1]
    ///      E.g. increment/decrement factor per 2000 seconds is 2
    ///      Weight growth range for 2000 seconds is [-50%, 100%]
    uint256 private constant MAX_WEIGHT_CHANGE_RATIO = 10**16;

    /// @notice Largest management fee earned proportion per one second.
    /// @dev 0.0000001% per second, i.e. 3.1536% per year.
    ///      0.0000001% * (365 * 24 * 60 * 60) = 3.1536%
    uint256 private constant MAX_MANAGEMENT_FEE = 10**9;

    /// @notice Balancer Vault.
    IBVault public immutable bVault;

    /// @notice Balancer Managed Pool.
    IBManagedPool public immutable pool;

    /// @notice Balancer Managed Pool Controller.
    IBManagedPoolController public immutable poolController;

    /// @notice Balancer Merkle Orchard.
    IBMerkleOrchard public immutable merkleOrchard;

    /// @notice Pool ID of Balancer pool on Vault.
    bytes32 public immutable poolId;

    /// @notice Notice period for vault termination (in seconds).
    uint256 public immutable noticePeriod;

    /// @notice Verifies withdraw limits.
    IWithdrawalValidator public immutable validator;

    /// @notice Management fee earned proportion per second.
    /// @dev 10**18 is 100%
    uint256 public immutable managementFee;

    /// STORAGE SLOT START ///

    /// @notice Describes vault purpose and modelling assumptions for differentiating between vaults
    /// @dev string cannot be immutable bytecode but only set in constructor
    // slither-disable-next-line immutable-states
    string public description;

    /// @notice Indicates that the Vault has been initialized
    bool public initialized;

    /// @notice Indicates that the Vault has been finalized
    bool public finalized;

    /// @notice Controls vault parameters.
    address public guardian;

    /// @notice Pending account to accept ownership of vault.
    address public pendingOwner;

    /// @notice Timestamp when notice elapses or 0 if not yet set
    uint256 public noticeTimeoutAt;

    /// @notice Last timestamp where guardian fee index was locked.
    uint256 public lastFeeCheckpoint = type(uint256).max;

    /// @notice Fee earned amount for each guardian
    mapping(address => uint256[]) public guardiansFee;

    /// @notice Total guardian fee earned amount
    uint256[] public guardiansFeeTotal;

    /// @notice Last timestamp where swap fee was updated.
    uint256 public lastSwapFeeCheckpoint;

    /// EVENTS ///

    /// @notice Emitted when the vault is created.
    /// @param factory Balancer Managed Pool factory address.
    /// @param name Name of Pool Token.
    /// @param symbol Symbol of Pool Token.
    /// @param tokens Token addresses.
    /// @param weights Token weights.
    /// @param swapFeePercentage Pool swap fee.
    /// @param guardian Vault guardian address.
    /// @param validator Withdrawal validator contract address.
    /// @param noticePeriod Notice period (in seconds).
    /// @param managementFee Management fee earned proportion per second.
    /// @param merkleOrchard Merkle Orchard address.
    /// @param description Vault description.
    event Created(
        address indexed factory,
        string name,
        string symbol,
        IERC20[] tokens,
        uint256[] weights,
        uint256 swapFeePercentage,
        address indexed guardian,
        address indexed validator,
        uint256 noticePeriod,
        uint256 managementFee,
        address merkleOrchard,
        string description
    );

    /// @notice Emitted when tokens are deposited.
    /// @param requestedAmounts Requested amounts to deposit.
    /// @param amounts Deposited amounts.
    /// @param weights Token weights following deposit.
    event Deposit(
        uint256[] requestedAmounts,
        uint256[] amounts,
        uint256[] weights
    );

    /// @notice Emitted when tokens are withdrawn.
    /// @param requestedAmounts Requested amounts to withdraw.
    /// @param amounts Withdrawn amounts.
    /// @param allowances Token withdrawal allowances.
    /// @param weights Token weights following withdrawal.
    event Withdraw(
        uint256[] requestedAmounts,
        uint256[] amounts,
        uint256[] allowances,
        uint256[] weights
    );

    /// @notice Emitted when management fees are withdrawn.
    /// @param guardian Guardian address.
    /// @param amounts Withdrawn amounts.
    event DistributeGuardianFees(address indexed guardian, uint256[] amounts);

    /// @notice Emitted when guardian is changed.
    /// @param previousGuardian Previous guardian address.
    /// @param guardian New guardian address.
    event GuardianChanged(
        address indexed previousGuardian,
        address indexed guardian
    );

    /// @notice Emitted when updateWeightsGradually is called.
    /// @param startTime Start timestamp of updates.
    /// @param endTime End timestamp of updates.
    /// @param weights Target weights of tokens.
    event UpdateWeightsGradually(
        uint256 startTime,
        uint256 endTime,
        uint256[] weights
    );

    /// @notice Emitted when cancelWeightUpdates is called.
    /// @param weights Current weights of tokens.
    event CancelWeightUpdates(uint256[] weights);

    /// @notice Emitted when swap is enabled/disabled.
    /// @param swapEnabled New state of swap.
    event SetSwapEnabled(bool swapEnabled);

    /// @notice Emitted when enableTradingWithWeights is called.
    /// @param time timestamp of updates.
    /// @param weights Target weights of tokens.
    event EnabledTradingWithWeights(uint256 time, uint256[] weights);

    /// @notice Emitted when swap fee is updated.
    /// @param swapFee New swap fee.
    event SetSwapFee(uint256 swapFee);

    /// @notice Emitted when initiateFinalization is called.
    /// @param noticeTimeoutAt Timestamp for notice timeout.
    event FinalizationInitiated(uint256 noticeTimeoutAt);

    /// @notice Emitted when vault is finalized.
    /// @param caller Address of finalizer.
    /// @param amounts Returned token amounts.
    event Finalized(address indexed caller, uint256[] amounts);

    /// @notice Emitted when transferOwnership is called.
    /// @param currentOwner Address of current owner.
    /// @param pendingOwner Address of pending owner.
    event OwnershipTransferOffered(
        address indexed currentOwner,
        address indexed pendingOwner
    );

    /// @notice Emitted when cancelOwnershipTransfer is called.
    /// @param currentOwner Address of current owner.
    /// @param canceledOwner Address of canceled owner.
    event OwnershipTransferCanceled(
        address indexed currentOwner,
        address indexed canceledOwner
    );

    /// ERRORS ///

    error Aera__ValueLengthIsNotSame(uint256 numTokens, uint256 numValues);
    error Aera__DifferentTokensInPosition(
        address actual,
        address sortedToken,
        uint256 index
    );
    error Aera__ValidatorIsNotMatched(
        uint256 numTokens,
        uint256 numAllowances
    );
    error Aera__ValidatorIsNotValid(address validator);
    error Aera__ManagementFeeIsAboveMax(uint256 actual, uint256 max);
    error Aera__NoticePeriodIsAboveMax(uint256 actual, uint256 max);
    error Aera__NoticeTimeoutNotElapsed(uint256 noticeTimeoutAt);
    error Aera__GuardianIsZeroAddress();
    error Aera__GuardianIsOwner(address newGuardian);
    error Aera__CallerIsNotGuardian();
    error Aera__SwapFeePercentageChangeIsAboveMax(uint256 actual, uint256 max);
    error Aera__DescriptionIsEmpty();
    error Aera__CallerIsNotOwnerOrGuardian();
    error Aera__WeightChangeEndBeforeStart();
    error Aera__WeightChangeStartTimeIsAboveMax(uint256 actual, uint256 max);
    error Aera__WeightChangeEndTimeIsAboveMax(uint256 actual, uint256 max);
    error Aera__WeightChangeDurationIsBelowMin(uint256 actual, uint256 min);
    error Aera__WeightChangeRatioIsAboveMax(
        address token,
        uint256 actual,
        uint256 max
    );
    error Aera__WeightIsAboveMax(uint256 actual, uint256 max);
    error Aera__WeightIsBelowMin(uint256 actual, uint256 min);
    error Aera__AmountIsBelowMin(uint256 actual, uint256 min);
    error Aera__AmountExceedAvailable(
        address token,
        uint256 amount,
        uint256 available
    );
    error Aera__NoAvailableFeeForCaller(address caller);
    error Aera__BalanceChangedInCurrentBlock();
    error Aera__CannotSweepPoolToken();
    error Aera__PoolSwapIsAlreadyEnabled();
    error Aera__CannotSetSwapFeeBeforeCooldown();
    error Aera__FinalizationNotInitiated();
    error Aera__VaultNotInitialized();
    error Aera__VaultIsAlreadyInitialized();
    error Aera__VaultIsFinalizing();
    error Aera__VaultIsAlreadyFinalized();
    error Aera__VaultIsNotRenounceable();
    error Aera__OwnerIsZeroAddress();
    error Aera__NotPendingOwner();
    error Aera__NoPendingOwnershipTransfer();

    /// MODIFIERS ///

    /// @dev Throws if called by any account other than the guardian.
    modifier onlyGuardian() {
        if (msg.sender != guardian) {
            revert Aera__CallerIsNotGuardian();
        }
        _;
    }

    /// @dev Throws if called by any account other than the owner or guardian.
    modifier onlyOwnerOrGuardian() {
        if (msg.sender != owner() && msg.sender != guardian) {
            revert Aera__CallerIsNotOwnerOrGuardian();
        }
        _;
    }

    /// @dev Throws if called before vault is initialized.
    modifier whenInitialized() {
        if (!initialized) {
            revert Aera__VaultNotInitialized();
        }
        _;
    }

    /// @dev Throws if called before finalization is initiated.
    modifier whenNotFinalizing() {
        if (noticeTimeoutAt != 0) {
            revert Aera__VaultIsFinalizing();
        }
        _;
    }

    /// FUNCTIONS ///

    /// @notice Initialize the contract by deploying new Balancer pool using the provided factory.
    /// @dev Tokens should be unique. Validator should conform to interface.
    ///      These are checked by Balancer in internal transactions:
    ///       If tokens are sorted in ascending order.
    ///       If swapFeePercentage is greater than minimum and less than maximum.
    ///       If total sum of weights is one.
    /// @param vaultParams Struct vault parameter.
    constructor(NewVaultParams memory vaultParams) {
        uint256 numTokens = vaultParams.tokens.length;

        if (numTokens != vaultParams.weights.length) {
            revert Aera__ValueLengthIsNotSame(
                numTokens,
                vaultParams.weights.length
            );
        }
        if (
            !ERC165Checker.supportsInterface(
                vaultParams.validator,
                type(IWithdrawalValidator).interfaceId
            )
        ) {
            revert Aera__ValidatorIsNotValid(vaultParams.validator);
        }
        // Use new block to avoid stack too deep issue
        {
            uint256 numAllowances = IWithdrawalValidator(vaultParams.validator)
                .allowance()
                .length;
            if (numTokens != numAllowances) {
                revert Aera__ValidatorIsNotMatched(numTokens, numAllowances);
            }
        }
        if (vaultParams.managementFee > MAX_MANAGEMENT_FEE) {
            revert Aera__ManagementFeeIsAboveMax(
                vaultParams.managementFee,
                MAX_MANAGEMENT_FEE
            );
        }
        if (vaultParams.noticePeriod > MAX_NOTICE_PERIOD) {
            revert Aera__NoticePeriodIsAboveMax(
                vaultParams.noticePeriod,
                MAX_NOTICE_PERIOD
            );
        }

        if (bytes(vaultParams.description).length == 0) {
            revert Aera__DescriptionIsEmpty();
        }
        checkGuardianAddress(vaultParams.guardian);

        address[] memory assetManagers = new address[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            assetManagers[i] = address(this);
        }

        // Deploys a new ManagedPool from ManagedPoolFactory
        // create(
        //     ManagedPool.NewPoolParams memory poolParams,
        //     BasePoolController.BasePoolRights calldata basePoolRights,
        //     ManagedPoolController.ManagedPoolRights calldata managedPoolRights,
        //     uint256 minWeightChangeDuration,
        // )
        //
        // - poolParams.mustAllowlistLPs should be true to prevent other accounts
        //   to use joinPool
        // - minWeightChangeDuration should be zero so that weights can be updated immediately
        //   in deposit, withdraw, cancelWeightUpdates and enableTradingWithWeights.
        pool = IBManagedPool(
            IBManagedPoolFactory(vaultParams.factory).create(
                IBManagedPoolFactory.NewPoolParams({
                    vault: IBVault(address(0)),
                    name: vaultParams.name,
                    symbol: vaultParams.symbol,
                    tokens: vaultParams.tokens,
                    normalizedWeights: vaultParams.weights,
                    assetManagers: assetManagers,
                    swapFeePercentage: vaultParams.swapFeePercentage,
                    pauseWindowDuration: 0,
                    bufferPeriodDuration: 0,
                    owner: address(this),
                    swapEnabledOnStart: false,
                    mustAllowlistLPs: true,
                    managementSwapFeePercentage: 0
                }),
                IBManagedPoolFactory.BasePoolRights({
                    canTransferOwnership: false,
                    canChangeSwapFee: true,
                    canUpdateMetadata: false
                }),
                IBManagedPoolFactory.ManagedPoolRights({
                    canChangeWeights: true,
                    canDisableSwaps: true,
                    canSetMustAllowlistLPs: false,
                    canSetCircuitBreakers: false,
                    canChangeTokens: false
                }),
                0
            )
        );

        // slither-disable-next-line reentrancy-benign
        bVault = pool.getVault();
        poolController = IBManagedPoolController(pool.getOwner());
        merkleOrchard = IBMerkleOrchard(vaultParams.merkleOrchard);
        poolId = pool.getPoolId();
        guardian = vaultParams.guardian;
        validator = IWithdrawalValidator(vaultParams.validator);
        noticePeriod = vaultParams.noticePeriod;
        description = vaultParams.description;
        managementFee = vaultParams.managementFee;
        guardiansFee[guardian] = new uint256[](numTokens);
        guardiansFeeTotal = new uint256[](numTokens);

        // slither-disable-next-line reentrancy-events
        emit Created(
            vaultParams.factory,
            vaultParams.name,
            vaultParams.symbol,
            vaultParams.tokens,
            vaultParams.weights,
            vaultParams.swapFeePercentage,
            vaultParams.guardian,
            vaultParams.validator,
            vaultParams.noticePeriod,
            vaultParams.managementFee,
            vaultParams.merkleOrchard,
            vaultParams.description
        );
        // slither-disable-next-line reentrancy-events
        emit GuardianChanged(UNSET_GUARDIAN_ADDRESS, vaultParams.guardian);
    }

    /// PROTOCOL API ///

    /// @inheritdoc IProtocolAPI
    function initialDeposit(TokenValue[] calldata tokenWithAmount)
        external
        override
        onlyOwner
    {
        if (initialized) {
            revert Aera__VaultIsAlreadyInitialized();
        }

        initialized = true;
        lastFeeCheckpoint = block.timestamp;

        IERC20[] memory tokens = getTokens();
        uint256 numTokens = tokens.length;
        uint256[] memory balances = new uint256[](numTokens);
        uint256[] memory amounts = getValuesFromTokenWithValues(
            tokenWithAmount,
            tokens
        );

        for (uint256 i = 0; i < numTokens; i++) {
            balances[i] = depositToken(tokens[i], amounts[i]);
        }

        bytes memory initUserData = abi.encode(IBVault.JoinKind.INIT, amounts);

        IBVault.JoinPoolRequest memory joinPoolRequest = IBVault
            .JoinPoolRequest({
                assets: tokens,
                maxAmountsIn: balances,
                userData: initUserData,
                fromInternalBalance: false
            });
        bVault.joinPool(poolId, address(this), address(this), joinPoolRequest);

        setSwapEnabled(true);
    }

    /// @inheritdoc IProtocolAPI
    function deposit(TokenValue[] calldata tokenWithAmount)
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
        whenNotFinalizing
    {
        depositTokens(tokenWithAmount);
    }

    /// @inheritdoc IProtocolAPI
    // slither-disable-next-line incorrect-equality
    function depositIfBalanceUnchanged(TokenValue[] calldata tokenWithAmount)
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
        whenNotFinalizing
    {
        (, , uint256 lastChangeBlock) = getTokensData();

        if (lastChangeBlock == block.number) {
            revert Aera__BalanceChangedInCurrentBlock();
        }

        depositTokens(tokenWithAmount);
    }

    /// @inheritdoc IProtocolAPI
    function withdraw(TokenValue[] calldata tokenWithAmount)
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
        whenNotFinalizing
    {
        withdrawTokens(tokenWithAmount);
    }

    /// @inheritdoc IProtocolAPI
    // slither-disable-next-line incorrect-equality
    function withdrawIfBalanceUnchanged(TokenValue[] calldata tokenWithAmount)
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
        whenNotFinalizing
    {
        (, , uint256 lastChangeBlock) = getTokensData();

        if (lastChangeBlock == block.number) {
            revert Aera__BalanceChangedInCurrentBlock();
        }

        withdrawTokens(tokenWithAmount);
    }

    /// @inheritdoc IProtocolAPI
    function initiateFinalization()
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
        whenNotFinalizing
    {
        lockGuardianFees();
        // slither-disable-next-line reentrancy-no-eth
        noticeTimeoutAt = block.timestamp + noticePeriod;
        setSwapEnabled(false);
        emit FinalizationInitiated(noticeTimeoutAt);
    }

    /// @inheritdoc IProtocolAPI
    // slither-disable-next-line timestamp
    function finalize()
        external
        override
        nonReentrant
        onlyOwner
        whenInitialized
    {
        if (finalized) {
            revert Aera__VaultIsAlreadyFinalized();
        }
        if (noticeTimeoutAt == 0) {
            revert Aera__FinalizationNotInitiated();
        }
        if (noticeTimeoutAt > block.timestamp) {
            revert Aera__NoticeTimeoutNotElapsed(noticeTimeoutAt);
        }

        finalized = true;

        uint256[] memory amounts = returnFunds();
        emit Finalized(owner(), amounts);
    }

    /// @inheritdoc IProtocolAPI
    // slither-disable-next-line timestamp
    function setGuardian(address newGuardian)
        external
        override
        nonReentrant
        onlyOwner
    {
        checkGuardianAddress(newGuardian);

        if (initialized && noticeTimeoutAt == 0) {
            lockGuardianFees();
        }

        if (guardiansFee[newGuardian].length == 0) {
            // slither-disable-next-line reentrancy-no-eth
            guardiansFee[newGuardian] = new uint256[](getTokens().length);
        }

        // slither-disable-next-line reentrancy-events
        emit GuardianChanged(guardian, newGuardian);

        // slither-disable-next-line missing-zero-check
        guardian = newGuardian;
    }

    /// @inheritdoc IProtocolAPI
    // prettier-ignore
    function sweep(address token, uint256 amount)
        external
        override
        onlyOwner
    {
        if (token == address(pool)) {
            revert Aera__CannotSweepPoolToken();
        }
        IERC20(token).safeTransfer(owner(), amount);
    }

    /// @inheritdoc IProtocolAPI
    function enableTradingRiskingArbitrage()
        external
        override
        onlyOwner
        whenInitialized
    {
        setSwapEnabled(true);
    }

    /// @inheritdoc IProtocolAPI
    function enableTradingWithWeights(TokenValue[] calldata tokenWithWeight)
        external
        override
        onlyOwner
        whenInitialized
    {
        if (pool.getSwapEnabled()) {
            revert Aera__PoolSwapIsAlreadyEnabled();
        }

        IERC20[] memory tokens = getTokens();

        uint256[] memory weights = getValuesFromTokenWithValues(
            tokenWithWeight,
            tokens
        );

        poolController.updateWeightsGradually(
            block.timestamp,
            block.timestamp,
            weights
        );
        poolController.setSwapEnabled(true);
        // slither-disable-next-line reentrancy-events
        emit EnabledTradingWithWeights(block.timestamp, weights);
    }

    /// @inheritdoc IProtocolAPI
    function disableTrading()
        external
        override
        onlyOwnerOrGuardian
        whenInitialized
    {
        setSwapEnabled(false);
    }

    /// @inheritdoc IProtocolAPI
    // prettier-ignore
    function claimRewards(
        IBMerkleOrchard.Claim[] calldata claims,
        IERC20[] calldata tokens
    )
        external
        override
        onlyOwner
        whenInitialized
    {
        merkleOrchard.claimDistributions(owner(), claims, tokens);
    }

    /// GUARDIAN API ///

    /// @inheritdoc IGuardianAPI
    // slither-disable-next-line timestamp
    function updateWeightsGradually(
        TokenValue[] calldata tokenWithWeight,
        uint256 startTime,
        uint256 endTime
    )
        external
        override
        nonReentrant
        onlyGuardian
        whenInitialized
        whenNotFinalizing
    {
        // These are to protect against the following vulnerability
        // https://forum.balancer.fi/t/vulnerability-disclosure/3179
        if (startTime > type(uint32).max) {
            revert Aera__WeightChangeStartTimeIsAboveMax(
                startTime,
                type(uint32).max
            );
        }
        if (endTime > type(uint32).max) {
            revert Aera__WeightChangeEndTimeIsAboveMax(
                endTime,
                type(uint32).max
            );
        }

        startTime = Math.max(block.timestamp, startTime);
        if (startTime > endTime) {
            revert Aera__WeightChangeEndBeforeStart();
        }
        if (startTime + MINIMUM_WEIGHT_CHANGE_DURATION > endTime) {
            revert Aera__WeightChangeDurationIsBelowMin(
                endTime - startTime,
                MINIMUM_WEIGHT_CHANGE_DURATION
            );
        }

        // Check if weight change ratio is exceeded
        uint256[] memory weights = pool.getNormalizedWeights();
        IERC20[] memory tokens = getTokens();
        uint256 numTokens = tokens.length;
        uint256[] memory targetWeights = getValuesFromTokenWithValues(
            tokenWithWeight,
            tokens
        );
        uint256 duration = endTime - startTime;
        uint256 maximumRatio = MAX_WEIGHT_CHANGE_RATIO * duration;

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 changeRatio = getWeightChangeRatio(
                weights[i],
                targetWeights[i]
            );

            if (changeRatio > maximumRatio) {
                revert Aera__WeightChangeRatioIsAboveMax(
                    address(tokens[i]),
                    changeRatio,
                    maximumRatio
                );
            }
        }

        poolController.updateWeightsGradually(
            startTime,
            endTime,
            targetWeights
        );

        // slither-disable-next-line reentrancy-events
        emit UpdateWeightsGradually(startTime, endTime, targetWeights);
    }

    /// @inheritdoc IGuardianAPI
    function cancelWeightUpdates()
        external
        override
        nonReentrant
        onlyGuardian
        whenInitialized
        whenNotFinalizing
    {
        uint256[] memory weights = pool.getNormalizedWeights();
        uint256 numWeights = weights.length;
        uint256 weightSum;

        for (uint256 i = 0; i < numWeights; i++) {
            weightSum += weights[i];
        }

        updateWeights(weights, weightSum);

        // slither-disable-next-line reentrancy-events
        emit CancelWeightUpdates(weights);
    }

    /// @inheritdoc IGuardianAPI
    // slither-disable-next-line timestamp
    function setSwapFee(uint256 newSwapFee)
        external
        override
        nonReentrant
        onlyGuardian
    {
        if (
            block.timestamp < lastSwapFeeCheckpoint + SWAP_FEE_COOLDOWN_PERIOD
        ) {
            revert Aera__CannotSetSwapFeeBeforeCooldown();
        }
        lastSwapFeeCheckpoint = block.timestamp;

        uint256 oldSwapFee = pool.getSwapFeePercentage();

        uint256 absoluteDelta = (newSwapFee > oldSwapFee)
            ? newSwapFee - oldSwapFee
            : oldSwapFee - newSwapFee;
        if (absoluteDelta > MAXIMUM_SWAP_FEE_PERCENT_CHANGE) {
            revert Aera__SwapFeePercentageChangeIsAboveMax(
                absoluteDelta,
                MAXIMUM_SWAP_FEE_PERCENT_CHANGE
            );
        }

        poolController.setSwapFeePercentage(newSwapFee);
        // slither-disable-next-line reentrancy-events
        emit SetSwapFee(newSwapFee);
    }

    /// @inheritdoc IGuardianAPI
    function claimGuardianFees()
        external
        override
        nonReentrant
        whenInitialized
        whenNotFinalizing
    {
        if (msg.sender == guardian) {
            lockGuardianFees();
        }

        if (guardiansFee[msg.sender].length == 0) {
            revert Aera__NoAvailableFeeForCaller(msg.sender);
        }

        IERC20[] memory tokens;
        uint256[] memory holdings;
        (tokens, holdings, ) = getTokensData();

        uint256 numTokens = tokens.length;
        uint256[] memory fees = guardiansFee[msg.sender];

        for (uint256 i = 0; i < numTokens; i++) {
            // slither-disable-next-line reentrancy-no-eth
            guardiansFeeTotal[i] -= fees[i];
            guardiansFee[msg.sender][i] = 0;
            tokens[i].safeTransfer(msg.sender, fees[i]);
        }

        // slither-disable-next-line reentrancy-no-eth
        if (msg.sender != guardian) {
            delete guardiansFee[msg.sender];
        }

        // slither-disable-next-line reentrancy-events
        emit DistributeGuardianFees(msg.sender, fees);
    }

    /// MULTI ASSET VAULT INTERFACE ///

    /// @inheritdoc IMultiAssetVault
    function holding(uint256 index) external view override returns (uint256) {
        uint256[] memory amounts = getHoldings();
        return amounts[index];
    }

    /// @inheritdoc IMultiAssetVault
    function getHoldings()
        public
        view
        override
        returns (uint256[] memory amounts)
    {
        (, amounts, ) = getTokensData();
    }

    /// USER API ///

    /// @inheritdoc IUserAPI
    // prettier-ignore
    function isSwapEnabled()
        external
        view
        override
        returns (bool)
    {
        return pool.getSwapEnabled();
    }

    /// @inheritdoc IUserAPI
    // prettier-ignore
    function getSwapFee()
        external
        view
        override
        returns (uint256)
    {
        return pool.getSwapFeePercentage();
    }

    /// @inheritdoc IUserAPI
    function getTokensData()
        public
        view
        override
        returns (
            IERC20[] memory,
            uint256[] memory,
            uint256
        )
    {
        return bVault.getPoolTokens(poolId);
    }

    /// @inheritdoc IUserAPI
    function getTokens()
        public
        view
        override
        returns (IERC20[] memory tokens)
    {
        (tokens, , ) = getTokensData();
    }

    /// @inheritdoc IUserAPI
    function getNormalizedWeights()
        external
        view
        override
        returns (uint256[] memory)
    {
        return pool.getNormalizedWeights();
    }

    /// @notice Disable ownership renounceable
    function renounceOwnership() public override onlyOwner {
        revert Aera__VaultIsNotRenounceable();
    }

    /// @inheritdoc IProtocolAPI
    function transferOwnership(address newOwner)
        public
        override(IProtocolAPI, Ownable)
        onlyOwner
    {
        if (newOwner == address(0)) {
            revert Aera__OwnerIsZeroAddress();
        }
        pendingOwner = newOwner;
        emit OwnershipTransferOffered(owner(), newOwner);
    }

    /// @inheritdoc IProtocolAPI
    function cancelOwnershipTransfer() external override onlyOwner {
        if (pendingOwner == address(0)) {
            revert Aera__NoPendingOwnershipTransfer();
        }
        emit OwnershipTransferCanceled(owner(), pendingOwner);
        pendingOwner = address(0);
    }

    /// @inheritdoc IUserAPI
    function acceptOwnership() external override {
        if (msg.sender != pendingOwner) {
            revert Aera__NotPendingOwner();
        }
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice Deposit amount of tokens.
    /// @dev Will only be called by deposit() and depositIfBalanceUnchanged()
    ///      It calls updateWeights() function which cancels
    ///      current active weights change schedule.
    /// @param tokenWithAmount Deposit tokens with amount.
    function depositTokens(TokenValue[] calldata tokenWithAmount) internal {
        lockGuardianFees();

        IERC20[] memory tokens;
        uint256[] memory holdings;
        (tokens, holdings, ) = getTokensData();
        uint256 numTokens = tokens.length;

        uint256[] memory weights = pool.getNormalizedWeights();
        uint256[] memory newBalances = new uint256[](numTokens);
        uint256[] memory amounts = getValuesFromTokenWithValues(
            tokenWithAmount,
            tokens
        );

        for (uint256 i = 0; i < numTokens; i++) {
            if (amounts[i] != 0) {
                newBalances[i] = depositToken(tokens[i], amounts[i]);
            }
        }

        /// Set managed balance of pool as amounts
        /// i.e. Deposit amounts of tokens to pool from Aera Vault
        updatePoolBalance(newBalances, IBVault.PoolBalanceOpKind.UPDATE);
        /// Decrease managed balance and increase cash balance of pool
        /// i.e. Move amounts from managed balance to cash balance
        updatePoolBalance(newBalances, IBVault.PoolBalanceOpKind.DEPOSIT);

        uint256[] memory newHoldings = getHoldings();
        uint256 weightSum;

        for (uint256 i = 0; i < numTokens; i++) {
            if (amounts[i] != 0) {
                weights[i] = (weights[i] * newHoldings[i]) / holdings[i];
                newBalances[i] = newHoldings[i] - holdings[i];
            }

            weightSum += weights[i];
        }

        /// It cancels current active weights change schedule
        /// and update weights with newWeights
        updateWeights(weights, weightSum);

        // slither-disable-next-line reentrancy-events
        emit Deposit(amounts, newBalances, pool.getNormalizedWeights());
    }

    /// @notice Withdraw tokens up to requested amounts.
    /// @dev Will only be called by withdraw() and withdrawIfBalanceUnchanged()
    ///      It calls updateWeights() function which cancels
    ///      current active weights change schedule.
    /// @param tokenWithAmount Requested tokens with amount.
    function withdrawTokens(TokenValue[] calldata tokenWithAmount) internal {
        lockGuardianFees();

        IERC20[] memory tokens;
        uint256[] memory holdings;
        (tokens, holdings, ) = getTokensData();
        uint256 numTokens = tokens.length;

        uint256[] memory allowances = validator.allowance();
        uint256[] memory weights = pool.getNormalizedWeights();
        uint256[] memory balances = new uint256[](numTokens);
        uint256[] memory amounts = getValuesFromTokenWithValues(
            tokenWithAmount,
            tokens
        );

        for (uint256 i = 0; i < numTokens; i++) {
            if (amounts[i] > holdings[i] || amounts[i] > allowances[i]) {
                revert Aera__AmountExceedAvailable(
                    address(tokens[i]),
                    amounts[i],
                    Math.min(holdings[i], allowances[i])
                );
            }

            if (amounts[i] != 0) {
                balances[i] = tokens[i].balanceOf(address(this));
            }
        }

        withdrawFromPool(amounts);

        uint256 weightSum;

        for (uint256 i = 0; i < numTokens; i++) {
            if (amounts[i] != 0) {
                balances[i] = tokens[i].balanceOf(address(this)) - balances[i];
                tokens[i].safeTransfer(owner(), balances[i]);

                uint256 newBalance = holdings[i] - amounts[i];
                weights[i] = (weights[i] * newBalance) / holdings[i];
            }

            weightSum += weights[i];
        }

        /// It cancels current active weights change schedule
        /// and update weights with newWeights
        updateWeights(weights, weightSum);

        // slither-disable-next-line reentrancy-events
        emit Withdraw(
            amounts,
            balances,
            allowances,
            pool.getNormalizedWeights()
        );
    }

    /// @notice Withdraw tokens from Balancer Pool to Aera Vault
    /// @dev Will only be called by withdrawTokens(), returnFunds()
    ///      and lockGuardianFees()
    function withdrawFromPool(uint256[] memory amounts) internal {
        uint256[] memory managed = new uint256[](amounts.length);

        /// Decrease cash balance and increase managed balance of pool
        /// i.e. Move amounts from cash balance to managed balance
        /// and withdraw token amounts from pool to Aera Vault
        updatePoolBalance(amounts, IBVault.PoolBalanceOpKind.WITHDRAW);
        /// Adjust managed balance of pool as the zero array
        updatePoolBalance(managed, IBVault.PoolBalanceOpKind.UPDATE);
    }

    /// @notice Calculate guardian fees and lock the tokens in Vault.
    /// @dev Will only be called by claimGuardianFees(), setGuardian(),
    ///      initiateFinalization(), deposit() and withdraw().
    // slither-disable-next-line timestamp
    function lockGuardianFees() internal {
        if (managementFee == 0) {
            return;
        }
        if (block.timestamp <= lastFeeCheckpoint) {
            return;
        }

        IERC20[] memory tokens;
        uint256[] memory holdings;
        (tokens, holdings, ) = getTokensData();

        uint256 numTokens = tokens.length;
        uint256[] memory newFees = new uint256[](numTokens);
        uint256[] memory balances = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            balances[i] = tokens[i].balanceOf(address(this));
            newFees[i] =
                (holdings[i] *
                    (block.timestamp - lastFeeCheckpoint) *
                    managementFee) /
                ONE;
        }

        lastFeeCheckpoint = block.timestamp;

        withdrawFromPool(newFees);

        for (uint256 i = 0; i < numTokens; i++) {
            newFees[i] = tokens[i].balanceOf(address(this)) - balances[i];
            // slither-disable-next-line reentrancy-benign
            guardiansFee[guardian][i] += newFees[i];
            guardiansFeeTotal[i] += newFees[i];
        }
    }

    /// @notice Calculate change ratio for weight upgrade.
    /// @dev Will only be called by updateWeightsGradually().
    /// @param weight Current weight.
    /// @param targetWeight Target weight.
    /// @return Change ratio(>1) from current weight to target weight.
    function getWeightChangeRatio(uint256 weight, uint256 targetWeight)
        internal
        pure
        returns (uint256)
    {
        return
            weight > targetWeight
                ? (ONE * weight) / targetWeight
                : (ONE * targetWeight) / weight;
    }

    /// @notice Return an array of values from given tokenWithValues.
    /// @dev Will only be called by enableTradingWithWeights(), updateWeightsGradually().
    ///      initialDeposit(), depositTokens() and withdrawTokens().
    ///      The values could be amounts or weights.
    /// @param tokenWithValues Tokens with values.
    /// @param tokens Array of pool tokens.
    /// @return Array of values.
    function getValuesFromTokenWithValues(
        TokenValue[] calldata tokenWithValues,
        IERC20[] memory tokens
    ) internal pure returns (uint256[] memory) {
        uint256 numTokens = tokens.length;

        if (numTokens != tokenWithValues.length) {
            revert Aera__ValueLengthIsNotSame(
                numTokens,
                tokenWithValues.length
            );
        }

        uint256[] memory values = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            if (address(tokenWithValues[i].token) != address(tokens[i])) {
                revert Aera__DifferentTokensInPosition(
                    address(tokenWithValues[i].token),
                    address(tokens[i]),
                    i
                );
            }
            values[i] = tokenWithValues[i].value;
        }

        return values;
    }

    /// @dev PoolBalanceOpKind has three kinds
    /// Withdrawal - decrease the Pool's cash, but increase its managed balance,
    ///              leaving the total balance unchanged.
    /// Deposit - increase the Pool's cash, but decrease its managed balance,
    ///           leaving the total balance unchanged.
    /// Update - don't affect the Pool's cash balance, but change the managed balance,
    ///          so it does alter the total. The external amount can be either
    ///          increased or decreased by this call (i.e., reporting a gain or a loss).
    function updatePoolBalance(
        uint256[] memory amounts,
        IBVault.PoolBalanceOpKind kind
    ) internal {
        uint256 numAmounts = amounts.length;
        IBVault.PoolBalanceOp[] memory ops = new IBVault.PoolBalanceOp[](
            numAmounts
        );
        IERC20[] memory tokens = getTokens();

        bytes32 balancerPoolId = poolId;
        for (uint256 i = 0; i < numAmounts; i++) {
            ops[i].kind = kind;
            ops[i].poolId = balancerPoolId;
            ops[i].token = tokens[i];
            ops[i].amount = amounts[i];
        }

        bVault.managePoolBalance(ops);
    }

    /// @notice Update weights of tokens in the pool.
    /// @dev Will only be called by deposit(), withdraw() and cancelWeightUpdates().
    function updateWeights(uint256[] memory weights, uint256 weightSum)
        internal
    {
        uint256 numWeights = weights.length;
        uint256[] memory newWeights = new uint256[](numWeights);

        uint256 adjustedSum;
        for (uint256 i = 0; i < numWeights; i++) {
            newWeights[i] = (weights[i] * ONE) / weightSum;
            adjustedSum += newWeights[i];
        }

        newWeights[0] = newWeights[0] + ONE - adjustedSum;

        poolController.updateWeightsGradually(
            block.timestamp,
            block.timestamp,
            newWeights
        );
    }

    /// @notice Deposit token to the pool.
    /// @dev Will only be called by deposit().
    /// @param token Address of the token to deposit.
    /// @param amount Amount to deposit.
    /// @return Actual deposited amount excluding fee on transfer.
    // slither-disable-next-line timestamp
    function depositToken(IERC20 token, uint256 amount)
        internal
        returns (uint256)
    {
        // slither-disable-next-line calls-loop
        uint256 balance = token.balanceOf(address(this));
        token.safeTransferFrom(owner(), address(this), amount);
        // slither-disable-next-line calls-loop
        balance = token.balanceOf(address(this)) - balance;

        // slither-disable-next-line calls-loop
        uint256 allowance = token.allowance(address(this), address(bVault));
        if (allowance > 0) {
            token.safeDecreaseAllowance(address(bVault), allowance);
        }
        token.safeIncreaseAllowance(address(bVault), balance);

        return balance;
    }

    /// @notice Return all funds to owner.
    /// @dev Will only be called by finalize().
    /// @return amounts Exact returned amount of tokens.
    function returnFunds() internal returns (uint256[] memory amounts) {
        IERC20[] memory tokens;
        uint256[] memory holdings;
        (tokens, holdings, ) = getTokensData();

        uint256 numTokens = tokens.length;
        amounts = new uint256[](numTokens);

        withdrawFromPool(holdings);

        uint256 amount;
        IERC20 token;
        for (uint256 i = 0; i < numTokens; i++) {
            token = tokens[i];
            amount = token.balanceOf(address(this)) - guardiansFeeTotal[i];
            token.safeTransfer(owner(), amount);
            amounts[i] = amount;
        }
    }

    /// @notice Enable or disable swap.
    /// @dev Will only be called by enableTradingRiskingArbitrage(), enableTradingWithWeights()
    ///      and disableTrading().
    /// @param swapEnabled Swap status.
    function setSwapEnabled(bool swapEnabled) internal {
        poolController.setSwapEnabled(swapEnabled);
        // slither-disable-next-line reentrancy-events
        emit SetSwapEnabled(swapEnabled);
    }

    /// @notice Check if the address can be a guardian.
    /// @dev Will only be called by constructor and setGuardian()
    /// @param newGuardian Address to check.
    function checkGuardianAddress(address newGuardian) internal {
        if (newGuardian == address(0)) {
            revert Aera__GuardianIsZeroAddress();
        }
        if (newGuardian == owner()) {
            revert Aera__GuardianIsOwner(newGuardian);
        }
    }
}