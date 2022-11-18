import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UniswapV2Helpers.sol";

library UniswapHelpers {
    using UniswapV2Helpers for IUniswapV2Router02;

    IUniswapV2Router02 constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // The ETH address according to 1inch API, this address is used as the address of the native token on all chains
    IERC20 constant ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @dev In handler meaning, we are providing an exact amount of input to receive a variable amount of output. This function also handles the routing to the appropriate uniswap V2 function
    function _exactInUniswapHandler(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _amountIn,
        uint256 _amountOutMinimum
    ) internal returns (uint256, uint256) {
        if (_fromToken == ETH) {
            revert("Swapping from ETH not supported");
            // ! Deprecated currently
            // (
            //     uint256 swappedAmountIn,
            //     uint256 swappedAmountOut
            // ) = uniswapV2Router._swapExactETHForTokens(
            //         _fromToken,
            //         _amountIn,
            //         _amountOutMinimum,
            //         address(this)
            //     );

            // return (swappedAmountIn, swappedAmountOut);
        } else if (_toToken == ETH) {
            (
                uint256 swappedAmountIn,
                uint256 swappedAmountOut
            ) = uniswapV2Router._swapExactTokensForETH(
                    _fromToken,
                    _amountIn,
                    _amountOutMinimum,
                    address(this)
                );

            return (swappedAmountIn, swappedAmountOut);
        } else {
            (
                uint256 swappedAmountIn,
                uint256 swappedAmountOut
            ) = uniswapV2Router._swapExactTokensForTokens(
                    _fromToken,
                    _toToken,
                    _amountIn,
                    _amountOutMinimum,
                    address(this)
                );
            return (swappedAmountIn, swappedAmountOut);
        }
    }
}