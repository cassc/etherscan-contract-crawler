// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IDeadDrop.sol";
import "./libraries/ErrorCodes.sol";

contract DeadDrop is IDeadDrop, AccessControl {
    using SafeERC20 for IERC20;

    /// @dev Value is the Keccak-256 hash of "GATEKEEPER"
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);

    ISwapRouter public swapRouter;

    /// @notice Whitelist for markets allowed as a withdrawal destination.
    mapping(IERC20 => IMToken) public allowedMarkets;

    /// @notice Whitelist for users who can be a withdrawal recipients
    mapping(address => bool) public allowedWithdrawReceivers;

    /// @dev Internal processing state of an address that is used for liquidation purposes
    mapping(address => mapping(uint256 => uint256)) public processingState;

    constructor(address admin_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
    }

    /************************************************************************/
    /*                          BOT FUNCTIONS                               */
    /************************************************************************/

    /// @inheritdoc IDeadDrop
    function performSwap(
        IERC20 tokenIn,
        uint256 tokenInAmount,
        IERC20 tokenOut,
        bytes calldata data
    ) external onlyRole(GATEKEEPER) {
        require(address(swapRouter) != address(0), ErrorCodes.DD_SWAP_ROUTER_IS_ZERO);

        require(address(tokenIn) != address(0), ErrorCodes.DD_INVALID_TOKEN_IN_ADDRESS);
        require(address(tokenOut) != address(0), ErrorCodes.DD_INVALID_TOKEN_OUT_ADDRESS);
        require(tokenInAmount > 0, ErrorCodes.DD_INVALID_TOKEN_IN_AMOUNT);

        require(address(allowedMarkets[tokenIn]) != address(0), ErrorCodes.DD_UNSUPPORTED_TOKEN);
        require(address(allowedMarkets[tokenOut]) != address(0), ErrorCodes.DD_UNSUPPORTED_TOKEN);

        uint256 amountInBefore = tokenIn.balanceOf(address(this));
        uint256 amountOutBefore = tokenOut.balanceOf(address(this));

        // slither-disable-next-line reentrancy-events
        tokenIn.safeApprove(address(swapRouter), tokenInAmount);

        // slither-disable-next-line reentrancy-events
        Address.functionCall(address(swapRouter), data, ErrorCodes.DD_SWAP_CALL_FAILS);

        uint256 amountInAfter = tokenIn.balanceOf(address(this));
        uint256 amountOutAfter = tokenOut.balanceOf(address(this));

        uint256 tokenInDelta = amountInBefore - amountInAfter;
        uint256 tokenOutDelta = amountOutAfter - amountOutBefore;

        emit Swap(tokenIn, tokenOut, tokenInDelta, tokenOutDelta);
    }

    /// @inheritdoc IDeadDrop
    function withdrawToProtocolInterest(uint256 amount, IERC20 underlying) external onlyRole(GATEKEEPER) {
        IMToken market = allowedMarkets[underlying];
        require(address(market) != address(0), ErrorCodes.DD_UNSUPPORTED_TOKEN);

        emit WithdrewToProtocolInterest(amount, underlying, market);

        underlying.safeApprove(address(market), amount);
        market.addProtocolInterest(amount);
    }

    /// @inheritdoc IDeadDrop
    function updateProcessingState(
        address target,
        uint256 hashValue,
        uint256 targetValue
    ) public onlyRole(GATEKEEPER) {
        uint256 currentValue = processingState[target][hashValue];
        emit NewProcessingState(target, hashValue, currentValue, targetValue);
        processingState[target][hashValue] = targetValue;
    }

    /************************************************************************/
    /*                        ADMIN FUNCTIONS                               */
    /************************************************************************/

    /* --- LOGIC --- */

    /// @inheritdoc IDeadDrop
    function withdraw(
        uint256 amount,
        IERC20 underlying,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) allowedReceiversOnly(to) {
        require(underlying.balanceOf(address(this)) >= amount, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        emit Withdraw(address(underlying), to, amount);
        underlying.safeTransfer(to, amount);
    }

    /* --- SETTERS --- */

    /// @inheritdoc IDeadDrop
    function addAllowedMarket(IMToken market) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(market) != address(0), ErrorCodes.DD_MARKET_ADDRESS_IS_ZERO);
        allowedMarkets[market.underlying()] = market;
        emit NewAllowedMarket(market.underlying(), market);
    }

    /// @inheritdoc IDeadDrop
    function setRouterAddress(ISwapRouter router) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(router) != address(0), ErrorCodes.DD_ROUTER_ADDRESS_IS_ZERO);
        require(swapRouter != router, ErrorCodes.DD_ROUTER_ALREADY_SET);
        swapRouter = router;
        emit NewSwapRouter(router);
    }

    /// @inheritdoc IDeadDrop
    function addAllowedReceiver(address receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(receiver != address(0), ErrorCodes.DD_RECEIVER_ADDRESS_IS_ZERO);
        require(!allowedWithdrawReceivers[receiver], ErrorCodes.DD_RECEIVER_ALREADY_SET);
        allowedWithdrawReceivers[receiver] = true;
        emit NewAllowedWithdrawReceiver(receiver);
    }

    /// @inheritdoc IDeadDrop
    function addAllowedBot(address bot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bot != address(0), ErrorCodes.DD_BOT_ADDRESS_IS_ZERO);
        require(!hasRole(GATEKEEPER, bot), ErrorCodes.DD_BOT_ALREADY_SET);
        _grantRole(GATEKEEPER, bot);
        emit NewAllowedBot(bot);
    }

    /* --- REMOVERS --- */

    /// @inheritdoc IDeadDrop
    function removeAllowedMarket(IERC20 underlying) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IMToken market = allowedMarkets[underlying];
        require(address(market) != address(0), ErrorCodes.DD_MARKET_NOT_FOUND);
        delete allowedMarkets[underlying];
        emit AllowedMarketRemoved(underlying, market);
    }

    /// @inheritdoc IDeadDrop
    function removeAllowedReceiver(address receiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        allowedReceiversOnly(receiver)
    {
        delete allowedWithdrawReceivers[receiver];
        emit AllowedWithdrawReceiverRemoved(receiver);
    }

    /// @inheritdoc IDeadDrop
    function removeAllowedBot(address bot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(GATEKEEPER, bot), ErrorCodes.DD_BOT_NOT_FOUND);
        _revokeRole(GATEKEEPER, bot);
        emit AllowedBotRemoved(bot);
    }

    /************************************************************************/
    /*                          INTERNAL FUNCTIONS                          */
    /************************************************************************/

    modifier allowedReceiversOnly(address receiver) {
        require(allowedWithdrawReceivers[receiver], ErrorCodes.DD_RECEIVER_NOT_FOUND);
        _;
    }
}