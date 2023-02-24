// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ILiquidation.sol";
import "./IMToken.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IDeadDrop is IAccessControl {
    event WithdrewToProtocolInterest(uint256 amount, IERC20 token, IMToken market);
    event Withdraw(address token, address to, uint256 amount);
    event NewLiquidation(ILiquidation liquidation);
    event NewSwapRouter(ISwapRouter router);
    event NewAllowedWithdrawReceiver(address receiver);
    event NewAllowedBot(address bot);
    event NewAllowedMarket(IERC20 token, IMToken market);
    event AllowedWithdrawReceiverRemoved(address receiver);
    event AllowedBotRemoved(address bot);
    event AllowedMarketRemoved(IERC20 token, IMToken market);
    event Swap(IERC20 tokenIn, IERC20 tokenOut, uint256 spentAmount, uint256 receivedAmount);
    event NewProcessingState(address target, uint256 hashValue, uint256 oldState, uint256 newState);
    event LiquidationFinalised(address target, uint256 hashValue);

    /**
     * @notice get Uniswap SwapRouter
     */
    function swapRouter() external view returns (ISwapRouter);

    /**
     * @notice get Whitelist for markets allowed as a withdrawal destination.
     */
    function allowedMarkets(IERC20) external view returns (IMToken);

    /**
     * @notice get whitelist for users who can be a withdrawal recipients
     */
    function allowedWithdrawReceivers(address) external view returns (bool);

    /**
     * @notice get keccak-256 hash of gatekeeper role
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
     * @notice Perform swap on Uniswap DEX
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param requiredState operation code that should precede the current operation
     * @param targetState operation code that will be assigned after successful swap
     * @param tokenIn input token
     * @param tokenInAmount amount of input token
     * @param tokenOut output token
     * @param data Uniswap calldata
     * @dev RESTRICTION: Gatekeeper only
     */
    function performSwap(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState,
        uint256 targetState,
        IERC20 tokenIn,
        uint256 tokenInAmount,
        IERC20 tokenOut,
        bytes calldata data
    ) external;

    /**
     * @notice Withdraw underlying asset to market's protocol interest
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param requiredState operation code that should precede the current operation
     * @param targetState operation code that will be assigned after successful withdrawal
     * @param amount Amount to withdraw
     * @param underlying Token to withdraw
     * @dev RESTRICTION: Gatekeeper only
     */
    function withdrawToProtocolInterest(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState,
        uint256 targetState,
        uint256 amount,
        IERC20 underlying
    ) external;

    /**
     * @notice Set processing state of started liquidation
     * @param target Address of the account under liquidation
     * @param hashValue Liquidation identity hash
     * @dev RESTRICTION: Liquidator contract only
     */
    function initialiseLiquidation(address target, uint256 hashValue) external;

    /**
     * @notice Update processing state of ongoing liquidation
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param targetState New state value of the liquidation
     * @dev RESTRICTION: Gatekeeper only
     */
    function updateProcessingState(
        address validationKey,
        uint256 validationHash,
        uint256 targetState
    ) external;

    /**
     * @notice Finalise processing state of ongoing liquidation
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param requiredState State value required to complete finalization
     * @dev RESTRICTION: Gatekeeper only
     */
    function finaliseLiquidation(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState
    ) external;

    /**
     * @notice Withdraw tokens to the wallet
     * @param amount Amount to withdraw
     * @param underlying Token to withdraw
     * @param to Receipient address
     * @dev RESTRICTION: Admin only
     */
    function withdraw(
        uint256 amount,
        IERC20 underlying,
        address to
    ) external;

    /**
     * @notice Add new market to the whitelist
     * @dev RESTRICTION: Admin only
     */
    function addAllowedMarket(IMToken market) external;

    /**
     * @notice Set new ILiquidation contract
     * @dev RESTRICTION: Admin only
     */
    function setLiquidationAddress(ILiquidation liquidationContract) external;

    /**
     * @notice Set new ISwapRouter router
     * @dev RESTRICTION: Admin only
     */
    function setRouterAddress(ISwapRouter router) external;

    /**
     * @notice Add new withdraw receiver address to the whitelist
     * @dev RESTRICTION: TIMELOCK only
     */
    function addAllowedReceiver(address receiver) external;

    /**
     * @notice Add new bot address to the whitelist
     * @dev RESTRICTION: Admin only
     */
    function addAllowedBot(address bot) external;

    /**
     * @notice Remove market from the whitelist
     * @dev RESTRICTION: Admin only
     */
    function removeAllowedMarket(IERC20 underlying) external;

    /**
     * @notice Remove withdraw receiver address from the whitelist
     * @dev RESTRICTION: TIMELOCK only
     */
    function removeAllowedReceiver(address receiver) external;

    /**
     * @notice Remove withdraw bot address from the whitelist
     * @dev RESTRICTION: Admin only
     */
    function removeAllowedBot(address bot) external;
}