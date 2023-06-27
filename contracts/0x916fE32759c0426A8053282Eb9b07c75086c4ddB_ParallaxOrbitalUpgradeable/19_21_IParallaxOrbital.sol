//SPDX-License-Identifier: MIT

import "../extensions/Timelock.sol";

import "./IParallax.sol";
import "./IParallaxStrategy.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

pragma solidity 0.8.15;

interface IParallaxOrbital is IParallax {
    /**
     * @param params parameters for deposit.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *               paths - paths that will be used during swaps.
     *               strategyId - an ID of an earning strategy.
     *               holder - user to whose address the deposit is made.
     *               positionId - id of the position.
     *               amounts - array of amounts to deposit.
     *               data - additional data for strategy.
     */
    struct DepositParams {
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 strategyId;
        address holder;
        uint256 positionId;
        uint256[] amounts;
        bytes[] data;
    }

    /**
     * @param params parameters for withdraw.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *               paths - paths that will be used during swaps.
     *               strategyId - an ID of an earning strategy.
     *               positionId - id of the position.
     *               earned - earnings for the current number of shares.
     *               amounts - array of amounts to deposit.
     *               receiver - address of the user who will receive
     *                          the withdrawn assets.
     *               data - additional data for strategy.
     */
    struct WithdrawParams {
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 strategyId;
        uint256 positionId;
        uint256 shares;
        address receiver;
        bytes[] data;
    }

    /**
     * @notice Deposit params with compoundAmountsOutMin.
     */
    struct DepositAndCompoundParams {
        bool toMakeCompound;
        uint256[] compoundAmountsOutMin;
        DepositParams depositParams;
    }

    /**
     * @notice Withdraw params with compoundAmountsOutMin.
     */
    struct WithdrawAndCompoundParams {
        bool toMakeCompound;
        uint256[] compoundAmountsOutMin;
        WithdrawParams withdrawParams;
    }

    /**
     * @notice Accepts deposits from users. This method accepts ERC-20 LP tokens
     *         that will be used in earning strategy. Appropriate amount of
     *         ERC-20 LP tokens must be approved for earning strategy in which
     *         it will be deposited. Can be called by anyone.
     * @param params A parameters for deposit (for more details see a
     *                      specific earning strategy).
     */
    function depositLPs(DepositAndCompoundParams memory params) external;

    /**
     * @notice Accepts deposits from users. This method accepts a group of
     *         different ERC-20 tokens in equal part that will be used in
     *         earning strategy (for more detail s see the specific earning
     *         strategy documentation). Appropriate amount of all ERC-20 tokens
     *         must be approved for earning strategy in which it will be
     *         deposited. Can be called by anyone.
     * @param params A parameters for deposit (for more details see a
     *                      specific earning strategy).
     */
    function depositTokens(DepositAndCompoundParams memory params) external;

    /**
     * @notice Accepts deposits from users. This method accepts ETH tokens that
     *         will be used in earning strategy. ETH tokens must be attached to
     *         the transaction. Can be called by anyone.
     * @param params A parameters for deposit (for more details see a
     *                      specific earning strategy).
     */
    function depositAndSwapNativeToken(
        DepositAndCompoundParams memory params
    ) external payable;

    /**
     * @notice Accepts deposits from users. This method accepts any whitelisted
     *         ERC-20 tokens that will be used in earning strategy. Appropriate
     *         amount of ERC-20 tokens must be approved for earning strategy in
     *         which it will be deposited. Can be called by anyone.
     * @param params A parameters parameters for deposit (for more
     *                      details see a specific earning strategy).
     */
    function depositAndSwapERC20Token(
        DepositAndCompoundParams memory params
    ) external;

    /**
     * @notice A withdraws users' deposits + reinvested yield. This method
     *         allows to withdraw ERC-20 LP tokens that were used in earning
     *         strategy. Can be called by anyone.
     * @param params A parameters for withdraw (for more details see a
     *                       specific earning strategy).
     */
    function withdrawLPs(WithdrawAndCompoundParams memory params) external;

    /**
     * @notice Withdraws users' deposits + reinvested yield. This method allows
     *         to withdraw a group of ERC-20 tokens in equal parts that were
     *         used in earning strategy (for more details see the specific
     *         earning strategy documentation). Can be called by anyone.
     * @param params A parameters for withdraw (for more details see a
     *                       specific earning strategy).
     */
    function withdrawTokens(WithdrawAndCompoundParams memory params) external;

    /**
     * @notice Withdraws users' deposits + reinvested yield. This method allows
     *         to withdraw ETH tokens that were used in earning strategy.Can be
     *         called by anyone.
     * @param params A parameters for withdraw (for more details see a
     *                       specific earning strategy).
     */
    function withdrawAndSwapForNativeToken(
        WithdrawAndCompoundParams memory params
    ) external;

    /**
     * @notice Withdraws users' deposits + reinvested yield. This method allows
     *         to withdraw any whitelisted ERC-20 tokens that were used in
     *         earning strategy. Can be called by anyone.
     * @param params A parameters for withdraw (for more details see a
     *                       specific earning strategy).
     */
    function withdrawAndSwapForERC20Token(
        WithdrawAndCompoundParams memory params
    ) external;

    /**
     * @notice Claims all rewards from earning strategy and reinvests them to
     *         increase future rewards. Can be called by anyone.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param amountsOutMin An array of minimum values that will be received
     *                      during exchanges, withdrawals or deposits of
     *                      liquidity, etc. The length of the array is unique
     *                      for each earning strategy. See the specific earning
     *                      strategy documentation for more details.
     */
    function compound(
        uint256 strategyId,
        uint256[] memory amountsOutMin
    ) external;

    /**
     * @notice Claims tokens that were distributed on users deposit and earned
     *         by a specific position of a user. Can be called by anyone.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param positionId An ID of a position. Must be an existing position ID.
     */
    function claim(uint256 strategyId, uint256 positionId) external;
}