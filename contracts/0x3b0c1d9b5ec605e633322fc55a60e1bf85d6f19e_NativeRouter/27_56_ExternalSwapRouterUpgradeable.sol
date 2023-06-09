// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IUniswapV3SwapRouter.sol";
import "./interfaces/IPeripheryState.sol";
import "./libraries/IWETH9.sol";
import "./libraries/Order.sol";
import "./libraries/FullMath.sol";

abstract contract ExternalSwapRouterUpgradeable is Initializable {
    using SafeERC20 for IERC20;

    address public pancakeswapRouter;

    // https://docs.uniswap.org/contracts/v3/reference/deployments
    // BSC: 0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2
    // Mainnet, Goerli, Arbitrum, Optimism, Polygon: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Celo: 0x5615CDAb10dc425a742d643d949a7F474C01abc4
    address public constant UNISWAP_V3_ROUTER_ADDRESS = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    uint24 public constant UNISWAP_V3_FEE_TIER = 500; // 0.05%

    event SwapPancake(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        bytes16 quoteId
    );

    event SwapUniswapV3(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        bytes16 quoteId
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

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
        address recipient,
        address payer
    ) internal returns (int256, int256) {
        require(order.deadlineTimestamp > block.timestamp, "Order is expired");
        require(flexibleAmount != 0, "Flexible amount cannot be 0");

        (uint256 buyerTokenAmount, uint256 sellerTokenAmount) = calculateTokenAmount(
            flexibleAmount,
            order
        );

        address tokenIn = order.sellerToken;
        address tokenOut = order.buyerToken;

        // handle the case where user call with ETH
        address weth9 = IPeripheryState(address(this)).WETH9();
        if (tokenIn == weth9 && address(this).balance >= sellerTokenAmount) {
            IWETH9(weth9).deposit{value: sellerTokenAmount}();
        } else if (payer != address(this)) {
            IERC20(tokenIn).safeTransferFrom(payer, address(this), sellerTokenAmount);
        }

        IERC20(tokenIn).safeApprove(address(pancakeswapRouter), sellerTokenAmount);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        require(
            sellerTokenAmount <= uint256(type(int256).max),
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
            outputAmounts[outputAmounts.length - 1] <= uint256(type(int256).max),
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
            order.quoteId
        );

        return (outputBuyerTokenAmount, outputSellerTokenAmount);
    }

    function swapUniswapV3(
        Orders.Order memory order,
        uint256 flexibleAmount,
        address recipient,
        address payer
    ) internal returns (int256, int256) {
        require(order.deadlineTimestamp > block.timestamp, "Order is expired");
        require(flexibleAmount != 0, "Flexible amount cannot be 0");

        (uint256 buyerTokenAmount, uint256 sellerTokenAmount) = calculateTokenAmount(
            flexibleAmount,
            order
        );

        address tokenIn = order.sellerToken;
        address tokenOut = order.buyerToken;

        // handle the case where user call with ETH
        address weth9 = IPeripheryState(address(this)).WETH9();
        if (tokenIn == weth9 && address(this).balance >= sellerTokenAmount) {
            IWETH9(weth9).deposit{value: sellerTokenAmount}();
        } else if (payer != address(this)) {
            IERC20(tokenIn).safeTransferFrom(payer, address(this), sellerTokenAmount);
        }

        IERC20(tokenIn).safeApprove(address(order.buyer), sellerTokenAmount);

        require(
            sellerTokenAmount <= uint256(type(int256).max),
            "sellerTokenAmount is too large and would cause an overflow error"
        );

        uint amountOut = IUniswapV3SwapRouter(order.buyer).exactInputSingle(
            IUniswapV3SwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: UNISWAP_V3_FEE_TIER,
                recipient: recipient,
                amountIn: sellerTokenAmount,
                amountOutMinimum: buyerTokenAmount,
                sqrtPriceLimitX96: 0
            })
        );

        require(
            amountOut <= uint256(type(int256).max),
            "buyerTokenAmount is too large and would cause an overflow error"
        );

        int256 outputSellerTokenAmount = int256(sellerTokenAmount);
        int256 outputBuyerTokenAmount = -1 * int256(amountOut);

        emit SwapUniswapV3(
            order.txOrigin,
            recipient,
            tokenIn,
            tokenOut,
            outputBuyerTokenAmount,
            outputSellerTokenAmount,
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
        require(sellerTokenAmount > 0, "Non-zero amount required");
        return (buyerTokenAmount, sellerTokenAmount);
    }

    uint256[49] private __gap;
}