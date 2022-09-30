// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/IBaseStrategy.sol";
import "../shared/BaseStorage.sol";
import "../shared/Constants.sol";

import "../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../libraries/Math.sol";
import "../libraries/Max/128Bit.sol";

/**
 * @notice Implementation of the {IBaseStrategy} interface.
 *
 * @dev
 * This implementation of the {IBaseStrategy} is meant to operate
 * on single-collateral strategies and uses a delta system to calculate
 * whether a withdrawal or deposit needs to be performed for a particular
 * strategy.
 */
abstract contract BaseStrategy is IBaseStrategy, BaseStorage, BaseConstants {
    using SafeERC20 for IERC20;
    using Max128Bit for uint128;

    /* ========== CONSTANTS ========== */

    /// @notice Value to multiply new deposit recieved to get the share amount
    uint128 private constant SHARES_MULTIPLIER = 10**6;
    
    /// @notice number of locked shares when initial shares are added
    /// @dev This is done to prevent rounding errors and share manipulation
    uint128 private constant INITIAL_SHARES_LOCKED = 10**11;

    /// @notice minimum shares size to avoid loss of share due to computation precision
    /// @dev If total shares go unders this value, new deposit is multiplied by the `SHARES_MULTIPLIER` again
    uint256 private constant MIN_SHARES_FOR_ACCURACY = INITIAL_SHARES_LOCKED * 10;

    /* ========== STATE VARIABLES ========== */

    /// @notice The total slippage slots the strategy supports, used for validation of provided slippage
    uint256 internal immutable rewardSlippageSlots;

    /// @notice Slots for processing
    uint256 internal immutable processSlippageSlots;

    /// @notice Slots for reallocation
    uint256 internal immutable reallocationSlippageSlots;

    /// @notice Slots for deposit
    uint256 internal immutable depositSlippageSlots;

    /** 
     * @notice do force claim of rewards.
     *
     * @dev
     * Some strategies auto claim on deposit/withdraw,
     * so execute the claim actions to store the reward amounts.
     */
    bool internal immutable forceClaim;

    /// @notice flag to force balance validation before running process strategy
    /// @dev this is done so noone can manipulate the strategies before we interact with them and cause harm to the system
    bool internal immutable doValidateBalance;

    /// @notice The self address, set at initialization to allow proper share accounting
    address internal immutable self;

    /// @notice The underlying asset of the strategy
    IERC20 public immutable override underlying;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Initializes the base strategy values.
     *
     * @dev
     * It performs certain pre-conditional validations to ensure the contract
     * has been initialized properly, such as that the address argument of the
     * underlying asset is valid.
     *
     * Slippage slots for certain strategies may be zero if there is no compounding
     * work to be done.
     * 
     * @param _underlying token used for deposits
     * @param _rewardSlippageSlots slots for rewards
     * @param _processSlippageSlots slots for processing
     * @param _reallocationSlippageSlots slots for reallocation
     * @param _depositSlippageSlots slots for deposits
     * @param _forceClaim force claim of rewards
     * @param _doValidateBalance force balance validation
     */
    constructor(
        IERC20  _underlying,
        uint256 _rewardSlippageSlots,
        uint256 _processSlippageSlots,
        uint256 _reallocationSlippageSlots,
        uint256 _depositSlippageSlots,
        bool _forceClaim,
        bool _doValidateBalance,
        address _self
    ) {
        require(
            _underlying != IERC20(address(0)),
            "BaseStrategy::constructor: Underlying address cannot be 0"
        );

        self = _self == address(0) ? address(this) : _self;

        underlying = _underlying;
        rewardSlippageSlots = _rewardSlippageSlots;
        processSlippageSlots = _processSlippageSlots;
        reallocationSlippageSlots = _reallocationSlippageSlots;
        depositSlippageSlots = _depositSlippageSlots;
        forceClaim = _forceClaim;
        doValidateBalance = _doValidateBalance;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Process the latest pending action of the strategy
     *
     * @dev
     * it yields amount of funds processed as well as the reward buffer of the strategy.
     * The function will auto-compound rewards if requested and supported.
     *
     * Requirements:
     *
     * - the slippages provided must be valid in length
     * - if the redeposit flag is set to true, the strategy must support
     *   compounding of rewards
     *
     * @param slippages slippages to process
     * @param redeposit if redepositing is to occur
     * @param swapData swap data for processing
     */
    function process(uint256[] calldata slippages, bool redeposit, SwapData[] calldata swapData) external override
    {
        slippages = _validateStrategyBalance(slippages);

        if (forceClaim || redeposit) {
            _validateRewardsSlippage(swapData);
            _processRewards(swapData);
        }

        if (processSlippageSlots != 0)
            _validateProcessSlippage(slippages);
        
        _process(slippages, 0);
    }

    /**
     * @notice Process first part of the reallocation DHW
     * @dev Withdraws for reallocation, depositn and withdraww for a user
     *
     * @param slippages Parameters to apply when performing a deposit or a withdraw
     * @param processReallocationData Data containing amuont of optimized and not optimized shares to withdraw
     * @return withdrawnReallocationReceived actual amount recieveed from peforming withdraw
     */
    function processReallocation(uint256[] calldata slippages, ProcessReallocationData calldata processReallocationData) external override returns(uint128) {
        slippages = _validateStrategyBalance(slippages);

        if (reallocationSlippageSlots != 0)
            _validateReallocationSlippage(slippages);

        _process(slippages, processReallocationData.sharesToWithdraw);

        uint128 withdrawnReallocationReceived = _updateReallocationWithdraw(processReallocationData);

        return withdrawnReallocationReceived;
    }

    /**
     * @dev Update reallocation batch storage for index after withdrawing reallocated shares
     * @param processReallocationData Data containing amount of optimized and not optimized shares to withdraw
     * @return Withdrawn reallocation received
     */
    function _updateReallocationWithdraw(ProcessReallocationData calldata processReallocationData) internal virtual returns(uint128) {
        Strategy storage strategy = strategies[self];
        uint24 stratIndex = _getProcessingIndex();
        BatchReallocation storage batch = strategy.reallocationBatches[stratIndex];

        // save actual withdrawn amount, without optimized one 
        uint128 withdrawnReallocationReceived = batch.withdrawnReallocationReceived;

        strategy.optimizedSharesWithdrawn += processReallocationData.optimizedShares;
        batch.withdrawnReallocationReceived += processReallocationData.optimizedWithdrawnAmount;
        batch.withdrawnReallocationShares = processReallocationData.optimizedShares + processReallocationData.sharesToWithdraw;

        return withdrawnReallocationReceived;
    }

    /**
     * @notice Process deposit
     * @param slippages Array of slippage parameters to apply when depositing
     */
    function processDeposit(uint256[] calldata slippages)
        external
        override
    {
        slippages = _validateStrategyBalance(slippages);

        if (depositSlippageSlots != 0)
            _validateDepositSlippage(slippages);
        _processDeposit(slippages);
    }

    /**
     * @notice Returns total starategy balance includign pending rewards
     * @return strategyBalance total starategy balance includign pending rewards
     */
    function getStrategyUnderlyingWithRewards() public view override returns(uint128)
    {
        return _getStrategyUnderlyingWithRewards();
    }

    /**
     * @notice Fast withdraw
     * @param shares Shares to fast withdraw
     * @param slippages Array of slippage parameters to apply when withdrawing
     * @param swapData Swap slippage and path array
     * @return Withdrawn amount withdawn
     */
    function fastWithdraw(uint128 shares, uint256[] calldata slippages, SwapData[] calldata swapData) external override returns(uint128)
    {
        slippages = _validateStrategyBalance(slippages);

        _validateRewardsSlippage(swapData);

        if (processSlippageSlots != 0)
            _validateProcessSlippage(slippages);

        uint128 withdrawnAmount = _processFastWithdraw(shares, slippages, swapData);
        strategies[self].totalShares -= shares;
        return withdrawnAmount;
    }

    /**
     * @notice Claims and possibly compounds strategy rewards.
     *
     * @param swapData swap data for processing
     */
    function claimRewards(SwapData[] calldata swapData) external override
    {
        _validateRewardsSlippage(swapData);
        _processRewards(swapData);
    }

    /**
     * @notice Withdraws all actively deployed funds in the strategy, liquifying them in the process.
     *
     * @param recipient recipient of the withdrawn funds
     * @param data data necessary execute the emergency withdraw
     */
    function emergencyWithdraw(address recipient, uint256[] calldata data) external virtual override {
        uint256 balanceBefore = underlying.balanceOf(address(this));
        _emergencyWithdraw(recipient, data);
        uint256 balanceAfter = underlying.balanceOf(address(this));

        uint256 withdrawnAmount = 0;
        if (balanceAfter > balanceBefore) {
            withdrawnAmount = balanceAfter - balanceBefore;
        }
        
        Strategy storage strategy = strategies[self];
        if (strategy.emergencyPending > 0) {
            withdrawnAmount += strategy.emergencyPending;
            strategy.emergencyPending = 0;
        }

        // also withdraw all unprocessed deposit for a strategy
        if (strategy.pendingUser.deposit.get() > 0) {
            withdrawnAmount += strategy.pendingUser.deposit.get();
            strategy.pendingUser.deposit = 0;
        }

        if (strategy.pendingUserNext.deposit.get() > 0) {
            withdrawnAmount += strategy.pendingUserNext.deposit.get();
            strategy.pendingUserNext.deposit = 0;
        }

        // if strategy was already processed in the current index that hasn't finished yet,
        // transfer the withdrawn amount
        // reset total underlying to 0
        if (strategy.index == globalIndex && doHardWorksLeft > 0) {
            uint256 withdrawnReceived = strategy.batches[strategy.index].withdrawnReceived;
            withdrawnAmount += withdrawnReceived;
            strategy.batches[strategy.index].withdrawnReceived = 0;

            strategy.totalUnderlying[strategy.index].amount = 0;
        }

        if (withdrawnAmount > 0) {
            // check if the balance is high enough to withdraw the total withdrawnAmount
            if (balanceAfter < withdrawnAmount) {
                // if not withdraw the current balance
                withdrawnAmount = balanceAfter;
            }

            underlying.safeTransfer(recipient, withdrawnAmount);
        }
    }

    /**
     * @notice Initialize a strategy.
     * @dev Execute strategy specific one-time actions if needed.
     */
    function initialize() external virtual override {}

    /**
     * @notice Disables a strategy.
     * @dev Cleans strategy specific values if needed.
     */
    function disable() external virtual override {}

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Validate strategy balance
     * @param slippages Check if the strategy balance is within defined min and max values
     * @return slippages Same array without first 2 slippages
     */
    function _validateStrategyBalance(uint256[] calldata slippages) internal virtual returns(uint256[] calldata) {
        if (doValidateBalance) {
            require(slippages.length >= 2, "BaseStrategy:: _validateStrategyBalance: Invalid number of slippages");
            uint128 strategyBalance =  getStrategyBalance();

            require(
                slippages[0] <= strategyBalance &&
                slippages[1] >= strategyBalance,
                "BaseStrategy::_validateStrategyBalance: Bad strategy balance"
            );

            return slippages[2:];
        }

        return slippages;
    }

    /**
     * @dev Validate reards slippage
     * @param swapData Swap slippage and path array
     */
    function _validateRewardsSlippage(SwapData[] calldata swapData) internal view virtual {
        if (swapData.length > 0) {
            require(
                swapData.length == _getRewardSlippageSlots(),
                "BaseStrategy::_validateSlippage: Invalid Number of reward slippages Defined"
            );
        }
    }

    /**
     * @dev Retrieve reward slippage slots
     * @return Reward slippage slots
     */
    function _getRewardSlippageSlots() internal view virtual returns(uint256) {
        return rewardSlippageSlots;
    }

    /**
     * @dev Validate process slippage
     * @param slippages parameters to verify validity of the strategy state
     */
    function _validateProcessSlippage(uint256[] calldata slippages) internal view virtual {
        _validateSlippage(slippages.length, processSlippageSlots);
    }

    /**
     * @dev Validate reallocation slippage
     * @param slippages parameters to verify validity of the strategy state
     */
    function _validateReallocationSlippage(uint256[] calldata slippages) internal view virtual {
        _validateSlippage(slippages.length, reallocationSlippageSlots);
    }

    /**
     * @dev Validate deposit slippage
     * @param slippages parameters to verify validity of the strategy state
     */
    function _validateDepositSlippage(uint256[] calldata slippages) internal view virtual {
        _validateSlippage(slippages.length, depositSlippageSlots);
    }

    /**
     * @dev Validates the provided slippage in length.
     * @param currentLength actual slippage array length
     * @param shouldBeLength expected slippages array length
     */
    function _validateSlippage(uint256 currentLength, uint256 shouldBeLength)
        internal
        view
        virtual
    {
        require(
            currentLength == shouldBeLength,
            "BaseStrategy::_validateSlippage: Invalid Number of Slippages Defined"
        );
    }

    /**
     * @dev Retrieve processing index
     * @return Processing index
     */
    function _getProcessingIndex() internal view returns(uint24) {
        return strategies[self].index + 1;
    }

    /**
     * @dev Calculates shares before they are added to the total shares
     * @param strategyTotalShares Total shares for strategy
     * @param stratTotalUnderlying Total underlying for strategy
     * @param depositAmount Deposit amount recieved
     * @return newShares New shares calculated
     */
    function _getNewSharesAfterWithdraw(uint128 strategyTotalShares, uint128 stratTotalUnderlying, uint128 depositAmount) internal pure returns(uint128, uint128){
        uint128 oldUnderlying;
        if (stratTotalUnderlying > depositAmount) {
            unchecked {
                oldUnderlying = stratTotalUnderlying - depositAmount;
            }
        }

        return _getNewShares(strategyTotalShares, oldUnderlying, depositAmount);
    }

    /**
     * @dev Calculates shares when they are already part of the total shares
     *
     * @param strategyTotalShares Total shares
     * @param stratTotalUnderlying Total underlying
     * @param depositAmount Deposit amount recieved
     * @return newShares New shares calculated
     */
    function _getNewShares(uint128 strategyTotalShares, uint128 stratTotalUnderlying, uint128 depositAmount) internal pure returns(uint128 newShares, uint128){
        if (strategyTotalShares <= MIN_SHARES_FOR_ACCURACY || stratTotalUnderlying == 0) {
            (newShares, strategyTotalShares) = _setNewShares(strategyTotalShares, depositAmount);
        } else {
            newShares = Math.getProportion128(depositAmount, strategyTotalShares, stratTotalUnderlying);
        }

        strategyTotalShares += newShares;

        return (newShares, strategyTotalShares);
    }

    /**
     * @notice Sets new shares if strategy does not have enough locked shares and calculated new shares based on deposit recieved
     * @dev
     * This is used when a strategy is new and does not have enough shares locked.
     * Shares are locked to prevent rounding errors and to keep share to underlying amount
     * ratio correct, to ensure the normal working of the share system._awaitingEmergencyWithdraw
     * We always want to have more shares than the underlying value of the strategy.
     *
     * @param strategyTotalShares Total shares
     * @param depositAmount Deposit amount recieved
     * @return newShares New shares calculated
     */
    function _setNewShares(uint128 strategyTotalShares, uint128 depositAmount) private pure returns(uint128, uint128) {
        // Enforce minimum shares size to avoid loss of share due to computation precision
        uint128 newShares = depositAmount * SHARES_MULTIPLIER;

        if (strategyTotalShares < INITIAL_SHARES_LOCKED) {
            if (newShares + strategyTotalShares >= INITIAL_SHARES_LOCKED) {
                unchecked {
                    uint128 newLockedShares = INITIAL_SHARES_LOCKED - strategyTotalShares;
                    strategyTotalShares += newLockedShares;
                    newShares -= newLockedShares;
                }
            } else {
                newShares = 0;
            }
        }

        return (newShares, strategyTotalShares);
    }

    /**
     * @dev Reset allowance to zero if previously set to a higher value.
     * @param token Asset
     * @param spender Spender address
     */
    function _resetAllowance(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.safeApprove(spender, 0);
        }
    }

    /* ========== VIRTUAL FUNCTIONS ========== */

    function getStrategyBalance()
        public
        view
        virtual
        override
        returns (uint128);

    function _processRewards(SwapData[] calldata) internal virtual;
    function _emergencyWithdraw(address recipient, uint256[] calldata data) internal virtual;
    function _process(uint256[] memory, uint128 reallocateSharesToWithdraw) internal virtual;
    function _processDeposit(uint256[] memory) internal virtual;
    function _getStrategyUnderlyingWithRewards() internal view virtual returns(uint128);
    function _processFastWithdraw(uint128, uint256[] memory, SwapData[] calldata) internal virtual returns(uint128);
}