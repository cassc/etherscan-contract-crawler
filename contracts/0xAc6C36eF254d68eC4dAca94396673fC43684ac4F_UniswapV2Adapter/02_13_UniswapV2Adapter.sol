// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/uniswap/v2-periphery/libraries/UniswapV2LiquidityMathLibrary.sol";
import "../interfaces/external/IWETH.sol";
import "../interfaces/IUniswapV2Adapter.sol";

error FlashLoanWithZeroAmounts();

contract UniswapV2Adapter is IUniswapV2Adapter {
    IUniswapV2Router02 public immutable router;
    IWETH public immutable nativeToken;

    constructor(IUniswapV2Router02 router_, IWETH nativeToken_) {
        router = router_;
        nativeToken = nativeToken_;
    }

    function swap(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_
    ) external payable override returns (uint256 _amountOut) {
        uint256 _last = path_.length - 1;
        address _tokenIn = path_[0];
        address _tokenOut = path_[_last];

        uint256 _tokenInBalance = IERC20(_tokenIn).balanceOf(address(this));
        if (_tokenIn == address(nativeToken) && _tokenInBalance > 0) {
            // Withdraw ETH from WETH if any
            nativeToken.withdraw(_tokenInBalance);
        }

        if (amountIn_ == type(uint256).max) {
            amountIn_ = _tokenIn == address(nativeToken) ? address(this).balance : _tokenInBalance;
        }

        if (amountIn_ == 0) {
            // Doesn't revert
            return 0;
        }

        if (_tokenIn == address(nativeToken)) {
            return
                router.swapExactETHForTokens{value: amountIn_}(amountOutMin_, path_, address(this), type(uint256).max)[
                    _last
                ];
        } else if (_tokenOut == address(nativeToken)) {
            return
                router.swapExactTokensForETH(amountIn_, amountOutMin_, path_, address(this), type(uint256).max)[_last];
        }

        return
            router.swapExactTokensForTokens(amountIn_, amountOutMin_, path_, address(this), type(uint256).max)[_last];
    }

    /**
     * @notice Calculate swap's `amountIn` and order (`aToB`) in order to balance target UniV2 pair
     * @dev `truePriceTokenA` and `truePriceTokenB` are used to set desired prices
     * E.g.: `truePriceTokenA = 1 && truePriceTokenB = 2` means that tokenA's price is 2x tokenB's price
     */
    function calculateMaxAmountIn(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB
    ) external view override returns (bool aToB, uint256 amountIn) {
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(router.factory(), tokenA, tokenB);
        (aToB, amountIn) = UniswapV2LiquidityMathLibrary.computeProfitMaximizingTrade(
            truePriceTokenA,
            truePriceTokenB,
            reserveA,
            reserveB
        );
    }

    function doFlashLoan(
        IUniswapV2Pair pair_,
        uint256 amount0_,
        uint256 amount1_,
        bytes memory data_
    ) external payable {
        if (amount0_ == 0 && amount1_ == 0) revert FlashLoanWithZeroAmounts();
        pair_.swap(amount0_, amount1_, address(this), data_);
    }

    receive() external payable {}
}