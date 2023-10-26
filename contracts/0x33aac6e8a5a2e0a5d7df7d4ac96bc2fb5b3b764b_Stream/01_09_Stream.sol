// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import { IStream } from "./IStream.sol";
import { Clone } from "solady/utils/Clone.sol";
import { IERC20 } from "openzeppelin-contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "openzeppelin-contracts/utils/math/Math.sol";

/**
 * @title Stream
 * @notice Allows a payer to pay a recipient an amount of tokens over time, at a regular rate per second.
 * Once the stream begins vested tokens can be withdrawn at any time.
 * Either party can choose to cancel, in which case the stream distributes each party's fair share of tokens.
 * @dev A fork of Sablier https://github.com/sablierhq/sablier/blob/%40sablier/protocol%401.1.0/packages/protocol/contracts/Sablier.sol.
 * Inherits from `Clone`, which allows Stream to read immutable arguments from its code section rather than state, resulting
 * in significant gas savings for users.
 */
contract Stream is IStream, Clone {
    using SafeERC20 for IERC20;

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   ERRORS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    error OnlyFactory();
    error CantWithdrawZero();
    error AmountExceedsBalance();
    error CallerNotPayerOrRecipient();
    error CallerNotPayer();
    error RescueTokenAmountExceedsExcessBalance();
    error StreamNotActive();
    error ETHRescueFailed();

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   EVENTS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @dev msgSender is part of the event to enable event indexing with which account performed this action.
    event TokensWithdrawn(address indexed msgSender, address indexed recipient, uint256 amount);

    /// @dev msgSender is part of the event to enable event indexing with which account performed this action.
    event StreamCancelled(
        address indexed msgSender,
        address indexed payer,
        address indexed recipient,
        uint256 recipientBalance
    );

    /// @notice Emitted when payer recovers excess stream payment tokens, or other ERC20 tokens accidentally sent to this stream
    event TokensRecovered(address indexed payer, address tokenAddress, uint256 amount, address to);

    /// @notice Emitted when recovering ETH accidentally sent to this stream
    event ETHRescued(address indexed payer, address indexed to, uint256 amount);

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   IMMUTABLES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Get the address of the factory contract that cloned this Stream instance.
     * @dev Uses clone-with-immutable-args to read the value from the contract's code region rather than state to save gas.
     */
    function factory() public pure returns (address) {
        return _getArgAddress(0);
    }

    /**
     * @notice Get this stream's payer address.
     * @dev Uses clone-with-immutable-args to read the value from the contract's code region rather than state to save gas.
     */
    function payer() public pure returns (address) {
        return _getArgAddress(20);
    }

    /**
     * @notice Get this stream's recipient address.
     * @dev Uses clone-with-immutable-args to read the value from the contract's code region rather than state to save gas.
     */
    function recipient() public pure returns (address) {
        return _getArgAddress(40);
    }

    /**
     * @notice Get this stream's total token amount.
     * @dev Uses clone-with-immutable-args to read the value from the contract's code region rather than state to save gas.
     */
    function tokenAmount() public pure returns (uint256) {
        return _getArgUint256(60);
    }

    /**
     * @notice Get this stream's ERC20 token.
     * @dev Uses clone-with-immutable-args to read the value from the contract's code region rather than state to save gas.
     */
    function token() public pure returns (IERC20) {
        return IERC20(_getArgAddress(92));
    }

    /**
     * @notice Get this stream's start timestamp in seconds.
     * @dev Uses clone-with-immutable-args to read the value from the contract's code region rather than state to save gas.
     */
    function startTime() public pure returns (uint256) {
        return _getArgUint256(112);
    }

    /**
     * @notice Get this stream's end timestamp in seconds.
     * @dev Uses clone-with-immutable-args to read the value from the contract's code region rather than state to save gas.
     */
    function stopTime() public pure returns (uint256) {
        return _getArgUint256(144);
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   STORAGE VARIABLES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice The maximum token balance remaining in the stream when taking withdrawals into account.
     * Should be equal to the stream's token balance once fully funded.
     * @dev using remaining balance rather than a growing sum of withdrawals for gas optimization reasons.
     * This approach warms up this slot upon stream creation, so that withdrawals cost less gas.
     * If this were the sum of withdrawals, recipient would pay 20K extra gas on their first withdrawal.
     */
    uint256 public remainingBalance;

    /**
     * @notice The recipient's balance once the stream is cancelled. It is set to the recipient's balance
     * at the moment of cancellation, and is decremented when recipient withdraws post-cancellation.
     * @dev It's assumed to be zero as long as the stream has not been cancelled.
     */
    uint256 public recipientCancelBalance;

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   MODIFIERS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @dev Reverts if the caller is not the payer or the recipient of the stream.
     */
    modifier onlyPayerOrRecipient() {
        if (msg.sender != recipient() && msg.sender != payer()) {
            revert CallerNotPayerOrRecipient();
        }

        _;
    }

    /**
     * @dev Reverts if the caller is not the payer of the stream.
     */
    modifier onlyPayer() {
        if (msg.sender != payer()) {
            revert CallerNotPayer();
        }

        _;
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   INITIALIZER
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @dev Limiting calls to factory only to prevent abuse. This approach is more gas efficient than using
     * OpenZeppelin's Initializable since we avoid the storage writes that entails.
     * This does create the possibility for the factory to initialize the same stream twice; this risk seems low
     * and worth the gas savings.
     */
    function initialize() external {
        if (msg.sender != factory()) revert OnlyFactory();

        remainingBalance = tokenAmount();
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   EXTERNAL TXS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Withdraw tokens to recipient's account.
     * Execution fails if the requested amount is greater than recipient's withdrawable balance.
     * Only this stream's payer or recipient can call this function.
     * @param amount the amount of tokens to withdraw.
     */
    function withdrawFromActiveBalance(uint256 amount) public onlyPayerOrRecipient {
        if (amount == 0) revert CantWithdrawZero();
        address recipient_ = recipient();

        uint256 balance = recipientActiveBalance();
        if (balance < amount) revert AmountExceedsBalance();

        // This is safe because it should always be the case that:
        // remainingBalance >= balance >= amount.
        unchecked {
            remainingBalance = remainingBalance - amount;
        }

        token().safeTransfer(recipient_, amount);
        emit TokensWithdrawn(msg.sender, recipient_, amount);
    }

    /**
     * @notice Cancel the stream and update recipient's fair share of the funds to their current balance.
     * Each party must take additional action to withdraw their funds:
     * recipient must call `withdrawAfterCancel`.
     * payer must call `recoverTokens`.
     * Only this stream's payer or recipient can call this function.
     * Reverts if executed after recipient has withdrawn the full stream amount, or if executed more than once.
     */
    function cancel() external onlyPayerOrRecipient {
        address payer_ = payer();
        address recipient_ = recipient();

        if (remainingBalance == 0) revert StreamNotActive();

        uint256 recipientActiveBalance_ = recipientActiveBalance();

        // This token amount is available to recipient to withdraw via `withdrawAfterCancel`.
        recipientCancelBalance = recipientActiveBalance_;

        // This zeroing is important because without it, it's possible for recipient to obtain additional funds
        // from this contract if anyone (e.g. payer) sends it tokens after cancellation.
        // Thanks to this state update, `balanceOf(recipient_)` will only return zero in future calls.
        remainingBalance = 0;

        emit StreamCancelled(msg.sender, payer_, recipient_, recipientActiveBalance_);
    }

    /**
     * @notice Withdraw tokens to recipient's account after the stream has been cancelled.
     * Execution fails if the requested amount is greater than recipient's withdrawable balance.
     * Only this stream's payer or recipient can call this function.
     * @param amount the amount of tokens to withdraw.
     */
    function withdrawAfterCancel(uint256 amount) public onlyPayerOrRecipient {
        if (amount == 0) revert CantWithdrawZero();
        address recipient_ = recipient();

        // Reverts if amount > recipientCancelBalance
        recipientCancelBalance -= amount;
        token().safeTransfer(recipient_, amount);

        emit TokensWithdrawn(msg.sender, recipient_, amount);
    }

    /**
     * @notice Withdraw tokens to recipients's account. Works for both active and cancelled streams.
     * @param amount the amount of tokens to withdraw
     * @dev reverts if msg.sender is not the payer or the recipient
     */
    function withdraw(uint256 amount) external {
        if (recipientCancelBalance > 0) {
            withdrawAfterCancel(amount);
        } else {
            withdrawFromActiveBalance(amount);
        }
    }

    /**
     * @notice Recover excess stream payment tokens, or other ERC20 tokens accidentally sent to this stream.
     * When a stream is cancelled payer uses this function to recover their fair share of tokens.
     * Reverts when trying to recover stream's payment token at an amount that exceeds
     * the excess token balance; any rescue should always leave sufficient tokens to
     * fully pay recipient.
     * Reverts when msg.sender is not this stream's payer.
     * @dev Checking token balance before and after to defend against the case of multiple contracts
     * updating the balance of the same token.
     * @param tokenAddress the contract address of the token to recover.
     * @param to the address to send the tokens to
     * @param amount the amount to recover.
     */
    function recoverTokens(address tokenAddress, uint256 amount, address to) public onlyPayer {
        // When the stream is under-funded, it should keep its current balance
        // When it's sufficiently-funded, it should keep the full balance committed to recipient
        // i.e. `remainingBalance` or `recipientCancelBalance`
        uint256 requiredBalanceAfter =
            Math.min(tokenBalance(), Math.max(remainingBalance, recipientCancelBalance));

        IERC20(tokenAddress).safeTransfer(to, amount);

        if (tokenBalance() < requiredBalanceAfter) revert RescueTokenAmountExceedsExcessBalance();

        emit TokensRecovered(msg.sender, tokenAddress, amount, to);
    }

    /**
     * @notice Recover maximumal amount of payment by `payer`
     * This can be used after canceling a stream to withdraw all the unvested tokens
     * @dev Reverts when msg.sender is not this stream's payer
     * @param to the address to send the tokens to
     * @return tokensToWithdraw the amount of tokens withdrawn
     */
    function recoverTokens(address to) external returns (uint256 tokensToWithdraw) {
        uint256 tokenBalance_ = tokenBalance();
        uint256 requiredBalanceAfter =
            Math.min(tokenBalance_, Math.max(remainingBalance, recipientCancelBalance));

        tokensToWithdraw = tokenBalance_ - requiredBalanceAfter;

        recoverTokens(address(token()), tokensToWithdraw, to);
    }

    /**
     * @notice Recover ETH accidentally sent to this stream.
     * Reverts if ETH sending failed.
     * @dev This is necessary because `LibClone` creates minimal clones with a default receive function, rather than
     * forwarding to clones, to support gas-restrictive transfers that might fail with the extra gas cost of DELEGATECALL.
     * So rather than block ETH transfers, we're allowing payer to recover ETH.
     * @param to the address to send ETH to, useful when payer might be a contract that can't receive ETH.
     * @param amount the amount of ETH to recover.
     */
    function rescueETH(address to, uint256 amount) external onlyPayer {
        (bool sent,) = to.call{value: amount}("");

        if (!sent) revert ETHRescueFailed();

        emit ETHRescued(msg.sender, to, amount);
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   VIEW FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Returns the time elapsed in this stream, or zero if it hasn't started yet.
     */
    function elapsedTime() public view returns (uint256) {
        uint256 startTime_ = startTime();
        if (block.timestamp <= startTime_) return 0;

        uint256 stopTime_ = stopTime();
        if (block.timestamp < stopTime_) return block.timestamp - startTime_;

        return stopTime_ - startTime_;
    }

    /**
     * @notice Get this stream's token balance vs the token amount required to meet the commitment
     * to recipient.
     */
    function tokenAndOutstandingBalance() public view returns (uint256, uint256) {
        return (tokenBalance(), remainingBalance);
    }

    /**
     * @notice Get this stream's recipient's balance, taking into account vesting over time and withdrawals.
     * When a stream is cancelled this function always returns zero, to make sure that `withdraw` no longer sends any funds.
     * To learn the recipient's balance post-cancel use `recipientCancelBalance`.
     */
    function recipientActiveBalance() public view returns (uint256) {
        uint256 startTime_ = startTime();
        uint256 stopTime_ = stopTime();
        uint256 blockTime = block.timestamp;

        if (blockTime <= startTime_) return 0;

        uint256 tokenAmount_ = tokenAmount();
        uint256 balance;
        if (blockTime >= stopTime_) {
            balance = tokenAmount_;
        } else {
            // This is safe because: blockTime > startTime_ (checked above).
            // and stopTime_ > startTime_ (checked in StreamFactory).
            unchecked {
                uint256 elapsedTime_ = blockTime - startTime_;
                uint256 duration = stopTime_ - startTime_;
                balance = elapsedTime_ * tokenAmount_ / duration;
            }
        }

        uint256 remainingBalance_ = remainingBalance;

        // When this function is called after the stream has been cancelled, when balance is less than
        // tokenAmount, without this early exit, the withdrawal calculation below results in an underflow error.
        if (remainingBalance_ == 0) return 0;

        // Take withdrawals into account
        if (tokenAmount_ > remainingBalance_) {
            // Should be safe because remainingBalance_ starts as equal to
            // tokenAmount_ when the stream starts and only grows smaller due to
            // withdrawals, so tokenAmount_ >= remainingBalance_ is always true.
            // Should also be always true that balance >= withdrawalAmount, since
            // at this point balance represents the total amount streamed to recipient
            // so far, which is always the upper bound of what could have been withdrawn.
            unchecked {
                uint256 withdrawalAmount = tokenAmount_ - remainingBalance_;
                balance -= withdrawalAmount;
            }
        }

        return balance;
    }

    /**
     * Returns the recipient balance. Works for both active and cancelled streams.
     */
    function recipientBalance() external view returns (uint256) {
        uint256 recipientCancelBalance_ = recipientCancelBalance;

        if (recipientCancelBalance_ > 0) {
            return recipientCancelBalance_;
        } else {
            return recipientActiveBalance();
        }
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   INTERNAL FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @dev Helper function that makes the rest of the code look nicer.
     */
    function tokenBalance() internal view returns (uint256) {
        return token().balanceOf(address(this));
    }
}