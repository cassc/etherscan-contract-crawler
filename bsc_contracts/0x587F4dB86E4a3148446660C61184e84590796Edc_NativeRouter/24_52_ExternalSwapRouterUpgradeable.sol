// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./libraries/Order.sol";
import "./libraries/FullMath.sol";

abstract contract ExternalSwapRouterUpgradeable is Initializable {
    address public pancakeswapRouter;

    event SwapPancake(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        // uint256 fee,
        bytes16 quoteId
    );

    function __ExternalSwapRouter_init(address _pancakeswapRouter) internal onlyInitializing {
        __ExternalSwapRouter_unchained(_pancakeswapRouter);
    }

    function __ExternalSwapRouter_unchained(address _pancakeswapRouter) internal onlyInitializing {
        _setPancakeswapRouter(_pancakeswapRouter);
    }

    function _setPancakeswapRouter(address _pancakeswapRouter) internal virtual {
        require(_pancakeswapRouter != address(0), "zero address input");
        pancakeswapRouter = _pancakeswapRouter;
    }

    function swapPancake(
        Orders.Order memory order,
        uint256 flexibleAmount,
        address recipient
    ) internal returns (int256, int256) {
        require(order.deadlineTimestamp > block.timestamp, "Order is expired");
        require(flexibleAmount != 0, "Flexible amount cannot be 0");

        (uint256 buyerTokenAmount, uint256 sellerTokenAmount) = calculateTokenAmount(
            flexibleAmount,
            order
        );

        address tokenIn = order.sellerToken;
        address tokenOut = order.buyerToken;

        if (order.seller != address(this)) {
            IERC20(tokenIn).transferFrom(order.seller, address(this), sellerTokenAmount);
        }
        IERC20(tokenIn).approve(address(pancakeswapRouter), sellerTokenAmount);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        require(
            sellerTokenAmount <= type(uint256).max / 2,
            "sellerTokenAmount is too large and would cause an overflow error"
        );

        uint[] memory outputAmounts = IPancakeRouter02(pancakeswapRouter).swapExactTokensForTokens(
            sellerTokenAmount,
            buyerTokenAmount,
            path,
            recipient,
            order.deadlineTimestamp
        );

        require(
            outputAmounts[outputAmounts.length - 1] <= type(uint256).max / 2,
            "buyerTokenAmount is too large and would cause an overflow error"
        );

        int256 outputSellerTokenAmount = int256(sellerTokenAmount);
        int256 outputBuyerTokenAmount = -1 * int256(outputAmounts[outputAmounts.length - 1]);

        emit SwapPancake(
            order.txOrigin,
            recipient,
            tokenIn,
            tokenOut,
            outputBuyerTokenAmount,
            outputSellerTokenAmount,
            // 0, // 0 fee from Native
            order.quoteId
        );

        return (outputBuyerTokenAmount, outputSellerTokenAmount);
    }

    function calculateTokenAmount(
        uint256 flexibleAmount,
        Orders.Order memory _order
    ) private pure returns (uint256, uint256) {
        uint256 buyerTokenAmount;
        uint256 sellerTokenAmount;

        sellerTokenAmount = flexibleAmount >= _order.sellerTokenAmount
            ? _order.sellerTokenAmount
            : flexibleAmount;

        require(
            _order.sellerTokenAmount > 0 && _order.buyerTokenAmount > 0,
            "Non-zero amount required"
        );

        buyerTokenAmount = FullMath.mulDiv(
            sellerTokenAmount,
            _order.buyerTokenAmount,
            _order.sellerTokenAmount
        );
        return (buyerTokenAmount, sellerTokenAmount);
    }

    uint256[49] private __gap;
}