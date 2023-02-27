// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// File: IMoneyInstant.sol

import './Types.sol';

/**
 * @title IMoneyInstant provides an interface to receive tokens and disburse tokens to multiple recipients at once.
 */

interface IMoneyInstant {
    /**
     * @notice Emits when an instant transfer is successfully created.
     */
    event InstantTransfer(
        string indexed id,
        address indexed sender,
        address indexed tokenAddress,
        uint256 deposit
    );

    /**
     * @notice Emits when the recipient withdraws a portion or all their tokens.
     */
    event InstantWithdraw(
        address indexed recipient,
        address indexed tokenAddress,
        uint256 amount
    );

    /**
     * @notice Emits when an native instant transfer is successfully created.
     */
    event NativeInstantTransfer(
        string indexed id,
        address indexed sender,
        uint256 deposit
    );

    /**
     * @notice Emits when the recipient withdraws a portion or all their native tokens.
     */
    event NativeInstantWithdraw(address indexed recipient, uint256 amount);

    /**
     * @notice Emits when the Owner gets paid.
     */
    event PayNiural(
        string indexed id,
        address indexed sender,
        address indexed tokenAddress,
        uint256 amount
    );

    /**
     * @notice Emits when the recipient receives the token through pay function.
     */
    event Pay(
        string indexed id,
        address indexed sender,
        address indexed tokenAddress,
        address recipient,
        uint256 amount
    );

    /**
     * @notice Creates a new instant transfer funded by `msg.sender` and paid towards `recipients`.
     * @dev The length of the payments is capped by the block gas limit.
     * Emits an {InstantTransfer} event
     *  Throws if the payments size is zero
     *  Throws if the recipient is the zero address, the contract itself or the caller.
     *  Throws if the contract is not allowed to transfer enough tokens.
     *  Throws if there is a token transfer failure.
     * @param tokenAddress The ERC20 token to used.
     * @param payments Array of recipient address and corresponding deposit
     */
    function createInstantTransfer(
        string calldata id,
        address tokenAddress,
        Types.Payment[] memory payments
    ) external;

    /**
     * @notice Withdraws from the contract to the recipient's account.
     * @dev Emits an {InstantWithdraw} event
     *  Throws if the amount is zero.
     *  Throws if the amount exceeds the available balance for the token.
     *  Throws if there is a token transfer failure.
     * @param tokenAddress The id of the stream to withdraw tokens from.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawInstant(address tokenAddress, uint256 amount) external;

    /**
     * @notice Gets TokenBalance of a specific token for the user.
     * @param recipient The address of the receiver wallet.
     * @param tokenAddress The address of the token to check balance of.
     * @return balance TokenBalance for the token.
     */
    function getTokenBalance(address recipient, address tokenAddress)
        external
        view
        returns (uint256 balance);

    /**
     * @notice Creates a new native token instant transfer funded by `msg.sender` and paid towards `recipients`.
     * The length of the deposits is capped by the block gas limit.
     * Emits an {nativeInstantTransfer} event
     *  Throws if the payments size is zero
     *  Throws if the recipient is the zero address, the contract itself or the caller.
     *  Throws if the contract did not receive native token as sum of payment tokens.
     *  Throws if there is a token transfer failure.
     * @param payments Array of recipient address and corresponding deposit
     */
    function createNativeTokenTransfer(
        string calldata id,
        Types.Payment[] memory payments
    ) external payable;

    /**
     * @notice Withdraws from the contract to the recipient's account.
     * @dev Emits an {NativeInstantWithdraw} event
     *  Throws if the amount is zero.
     *  Throws if the amount exceeds the available balance for the native token.
     *  Throws if there is a token transfer failure.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawNativeInstant(uint256 amount) external;

    /**
     * @notice Gets Native TokenBalance of user.
     * @param recipient The address of the receiver wallet.
     * @return balance TokenBalance for the token.
     */
    function getNativeBalance(address recipient)
        external
        view
        returns (uint256 balance);

    /**
     * @notice Pay niural fee to owner.
     * @dev Emits an {Payniural} event
     *  Throws if the amount is zero.
     * @param amount The amount of tokens to pay.
     * @param tokenAddress The ERC20 token to be used.
     */
    function payNiural(
        string calldata id,
        address tokenAddress,
        uint256 amount
    ) external;

    /**
     * @notice Pay @param recipient @param amount.
     *  Throws if the amount is zero.
     * @param amount The amount of tokens to pay.
     * @param tokenAddress The ERC20 token to be used.
     * @param recipient The address of the recipient
     */
    function pay(
        string calldata id,
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;
}