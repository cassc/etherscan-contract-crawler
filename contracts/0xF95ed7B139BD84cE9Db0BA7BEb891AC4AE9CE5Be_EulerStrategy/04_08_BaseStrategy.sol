// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

import "./interfaces/IStrategy.sol";
import "./interfaces/IBentoBoxMinimal.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// @title Base contract for BentoBox Strategies
/// @dev Extend the contract and implement _skim, _harvest, _withdraw, _exit and _harvestRewards methods.
abstract contract BaseStrategy is IStrategy, Owned {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the token in strategy
    ERC20 public immutable strategyToken;

    /// @notice address of bentobox
    IBentoBoxMinimal private immutable bentoBox;

    /// @notice address of the performance fee receiver
    address public feeTo;

    /*//////////////////////////////////////////////////////////////
                            STRATEGY STATES
    //////////////////////////////////////////////////////////////*/

    /// @notice status of the exit strategy
    /// @dev After bentobox 'exits' the strategy harvest and withdraw functions can no longer be called.
    bool private _exited;

    /// @notice slippage protection during harvest
    uint256 private _maxBentoBoxBalance;

    /// @notice performance fee
    uint256 public fee;

    /// @notice performance fee precision
    uint256 public FEE_PRECISION = 1e18;

    /// @notice executors address status
    mapping(address => bool) public strategyExecutors;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogSetStrategyExecutor(address indexed executor, bool allowed);
    event LogSetSwapPath(address indexed input, address indexed output);
    event LogFeeUpdated(uint256 fee);
    event LogFeeToUpdated(address newFeeTo);
    event LogPerformanceFee(ERC20 indexed token, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error StrategyExited();
    error StrategyNotExited();
    error OnlyBentoBox();
    error OnlyExecutor();
    error InvalidFee();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice sets the strategy configurations
    /// @param _bentoBox address of the bentobox
    /// @param _strategyToken address of the token in strategy
    /// @param _strategyExecutor address of the executor
    /// @param _feeTo address of the fee recipient
    /// @param _owner address of the owner of the strategy
    /// @param _fee fee for the strategy
    constructor(
        address _bentoBox,
        address _strategyToken,
        address _strategyExecutor,
        address _feeTo,
        address _owner,
        uint256 _fee
    ) Owned(_owner) {
        strategyToken = ERC20(_strategyToken);
        bentoBox = IBentoBoxMinimal(_bentoBox);
        strategyExecutors[_strategyExecutor] = true;
        feeTo = _feeTo;
        if (_fee >= 1e18) revert InvalidFee();
        fee = _fee;
        emit LogFeeUpdated(_fee);
        emit LogSetStrategyExecutor(_strategyExecutor, true);
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS 
    //////////////////////////////////////////////////////////////*/

    modifier isActive() {
        if (_exited) {
            revert StrategyExited();
        }
        _;
    }

    modifier onlyBentoBox() {
        if (msg.sender != address(bentoBox)) {
            revert OnlyBentoBox();
        }
        _;
    }

    modifier onlyExecutor() {
        if (!strategyExecutors[msg.sender]) {
            revert OnlyExecutor();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        STRATEGY CONFIG FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the status of the executors
    /// @param executor address of the executor to be updated
    /// @param status status of the exectuor to be updated
    function setStrategyExecutor(address executor, bool status)
        external
        onlyOwner
    {
        strategyExecutors[executor] = status;
        emit LogSetStrategyExecutor(executor, status);
    }

    /// @notice Sets the performance fee
    /// @param newFee new fee
    /// @dev should be less than 1e18 (cannot set it to 100%)
    function setFee(uint256 newFee) external onlyOwner {
        if (newFee >= 1e18) revert InvalidFee();
        fee = newFee;
        emit LogFeeUpdated(newFee);
    }

    /// @notice Sets the fee receiver
    /// @param newFeeTo address of the new fee receiver
    function setFeeTo(address newFeeTo) external onlyOwner {
        feeTo = newFeeTo;
        emit LogFeeToUpdated(newFeeTo);
    }

    /*//////////////////////////////////////////////////////////////
                        OVERRIDE FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    /// @notice Invests the underlying asset.
    /// @param amount The amount of tokens to invest.
    /// @dev Assume the contract's balance is greater than the amount.
    function _skim(uint256 amount) internal virtual;

    /// @notice Harvest any profits made and transfer them to address(this) or report a loss.
    /// @param balance The amount of tokens that have been invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    /// @dev amountAdded can be left at 0 when reporting profits (gas savings).
    /// amountAdded should not reflect any rewards or tokens the strategy received.
    /// Calculate the amount added based on what the current deposit is worth.
    /// (The Base Strategy harvest function accounts for rewards).
    function _harvest(uint256 balance)
        internal
        virtual
        returns (int256 amountAdded);

    /// @dev Withdraw the requested amount of the underlying tokens to address(this).
    /// @param amount The requested amount we want to withdraw.
    function _withdraw(uint256 amount) internal virtual;

    /// @notice Withdraw the maximum available amount of the invested assets to address(this).
    /// @dev This shouldn't revert (use try catch).
    function _exit() internal virtual;

    /// @notice Claim any reward tokens and optionally sell them for the underlying token.
    /// @dev Doesn't need to be implemented if we don't expect any rewards.
    function _harvestRewards() internal virtual {}

    /// @inheritdoc IStrategy
    function skim(uint256 amount) external override {
        _skim(amount);
    }

    /// @notice Harvest profits while preventing a sandwich attack exploit.
    /// @param maxBalanceInBentoBox The maximum balance of the underlying token that is allowed to be in BentoBox.
    /// @param rebalance Whether BentoBox should rebalance the strategy assets to acheive it's target allocation.
    /// @param maxChangeAmount When rebalancing - the maximum amount that will be deposited to or withdrawn from a strategy to BentoBox.
    /// @param harvestRewards If we want to claim any accrued reward tokens
    /// @dev maxBalance can be set to 0 to keep the previous value.
    /// @dev maxChangeAmount can be set to 0 to allow for full rebalancing.
    function safeHarvest(
        uint256 maxBalanceInBentoBox,
        bool rebalance,
        uint256 maxChangeAmount,
        bool harvestRewards
    ) external onlyExecutor {
        if (harvestRewards) {
            _harvestRewards();
        }

        if (maxBalanceInBentoBox > 0) {
            _maxBentoBoxBalance = maxBalanceInBentoBox;
        }

        bentoBox.harvest(address(strategyToken), rebalance, maxChangeAmount);
    }

    /** @inheritdoc IStrategy
    @dev Only BentoBox can call harvest on this strategy.
    @dev Ensures that (1) the caller was this contract (called through the safeHarvest function)
        and (2) that we are not being frontrun by a large BentoBox deposit when harvesting profits. */
    function harvest(uint256 balance, address sender)
        external
        override
        isActive
        onlyBentoBox
        returns (int256)
    {
        /** @dev Don't revert if conditions aren't met in order to allow
            BentoBox to continue execution as it might need to do a rebalance. */
        if (
            sender != address(this) ||
            bentoBox.totals(address(strategyToken)).elastic >
            _maxBentoBoxBalance ||
            balance == 0
        ) return int256(0);

        int256 amount = _harvest(balance);

        /** @dev We might have some underlying tokens in the contract that the _harvest call doesn't report. 
        E.g. reward tokens that have been sold into the underlying tokens which are now sitting in the contract.
        Meaning the amount returned by the internal _harvest function isn't necessary the final profit/loss amount */

        uint256 contractBalance = strategyToken.balanceOf(address(this)); // Reasonably assume this is less than type(int256).max

        if (amount > 0) {
            // _harvest reported a profit

            uint256 totalFee = (contractBalance * fee) / FEE_PRECISION;
            uint256 deltaProfit = contractBalance - totalFee;

            strategyToken.safeTransfer(feeTo, totalFee);

            emit LogPerformanceFee(strategyToken, totalFee);

            strategyToken.safeTransfer(address(bentoBox), deltaProfit);

            return int256(deltaProfit);
        } else if (contractBalance > 0) {
            // _harvest reported a loss but we have some tokens sitting in the contract

            int256 diff = amount + int256(contractBalance);

            if (diff > 0) {
                // We still made some profit.
                uint256 totalFee = (uint256(diff) * fee) / FEE_PRECISION;
                diff = diff - int256(totalFee);

                strategyToken.safeTransfer(feeTo, totalFee);
                emit LogPerformanceFee(strategyToken, totalFee);

                // Send the profit to BentoBox and reinvest the rest.
                strategyToken.safeTransfer(address(bentoBox), uint256(diff));
                _skim(contractBalance - uint256(diff) - totalFee);
            } else {
                // We made a loss but we have some tokens we can reinvest.

                _skim(contractBalance);
            }

            return diff;
        } else {
            // We made a loss.

            return amount;
        }
    }

    /// @inheritdoc IStrategy
    function withdraw(uint256 amount)
        external
        override
        isActive
        onlyBentoBox
        returns (uint256 actualAmount)
    {
        _withdraw(amount);
        // Make sure we send and report the exact same amount of tokens by using balanceOf.
        actualAmount = strategyToken.balanceOf(address(this));
        strategyToken.safeTransfer(address(bentoBox), actualAmount);
    }

    /// @inheritdoc IStrategy
    /// @dev Do not use isActive modifier here. Allow bentobox to call strategy.exit() multiple times
    /// This is to ensure that the strategy isn't locked if its (accidentally) set twice in a row as a token's strategy in bentobox.
    function exit(uint256 balance)
        external
        override
        onlyBentoBox
        returns (int256 amountAdded)
    {
        _exit();
        // Flag as exited, allowing the owner to manually deal with any amounts available later.
        _exited = true;
        // Check balance of token on the contract.
        uint256 actualBalance = strategyToken.balanceOf(address(this));
        // Calculate tokens added (or lost).
        // We reasonably assume actualBalance and balance are less than type(int256).max
        amountAdded = int256(actualBalance) - int256(balance);
        // Transfer all tokens to bentoBox.
        strategyToken.safeTransfer(address(bentoBox), actualBalance);
    }

    /** @dev After exited, the owner can perform ANY call. This is to rescue any funds that didn't
        get released during exit or got earned afterwards due to vesting or airdrops, etc. */
    function afterExit(
        address to,
        uint256 value,
        bytes memory data
    ) external onlyOwner returns (bool success) {
        if (!_exited) {
            revert StrategyNotExited();
        }
        (success, ) = to.call{value: value}(data);
        require(success);
    }

    function exited() public view returns (bool) {
        return _exited;
    }

    function maxBentoBoxBalance() public view returns (uint256) {
        return _maxBentoBoxBalance;
    }
}