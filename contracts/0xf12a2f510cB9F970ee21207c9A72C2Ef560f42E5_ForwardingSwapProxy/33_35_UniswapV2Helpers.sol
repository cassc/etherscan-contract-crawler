import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IERC20Extension.sol";

library UniswapV2Helpers {
    IERC20Extension constant WETH =
        IERC20Extension(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IUniswapV2Factory constant uniswapV2Factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    /// @dev Simple wrapper for the swapTokensForExactETH uniswap V2 function
    function _swapTokensForExactETH(
        IUniswapV2Router02 _uniswapV2Router,
        IERC20 _token,
        uint256 _amountOut,
        uint256 _amountInMaximum,
        address _to
    ) internal returns (uint256 amountIn, uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = address(WETH);

        uint256[] memory amounts = _uniswapV2Router.swapTokensForExactETH(
            _amountOut,
            _amountInMaximum,
            path,
            _to,
            block.timestamp
        );

        return (amounts[0], amounts[1]);
    }

    /// @notice This function calculates a path for swapping _fromToken for _toToken
    function _returnUniswapV2Path(IERC20 _fromToken, IERC20 _toToken)
        internal
        view
        returns (address[] memory path)
    {
        // Try to find a direct pair address for the given tokens
        try
            uniswapV2Factory.getPair(address(_fromToken), address(_toToken))
        returns (address _pairAddress) {
            // If a direct pair exists, return the direct path
            if (_pairAddress != address(0)) {
                // Been finding some direct pairs have old pools no one uses, so get the timestamp when the pool was used last
                (, , uint256 blocktimestampLast) = IUniswapV2Pair(_pairAddress)
                    .getReserves();

                // If the pool has been used within the last day, then route through the pool. If its been inactive longer than a day then its highly likely its a low liquidity pool and we don't want to route through it.

                // This is a cheap solution, it could pull the reserves from the pool and calculate the amount of stored liquidity in the pool in ETH and invalidate if less than a liquidity threshold. But that would cost a lot more gas and this seems ok for the current MVP
                if (block.timestamp - blocktimestampLast < 86400) {
                    path = new address[](2);

                    path[0] = address(_fromToken);
                    path[1] = address(_toToken);

                    return path;
                }
            }
        } catch {}

        // Return an empty path here, the route can't be handled if either of the tokens are WETH
        if (_fromToken == WETH || _toToken == WETH) {
            return path;
        }

        // Otherwise create a path through WETH
        path = new address[](3);

        path[0] = address(_fromToken);
        path[1] = address(WETH);
        path[2] = address(_toToken);
    }

    /// @dev Simple wrapper for the swapExactTokensForTokens uniswap V2 function
    function _swapExactTokensForTokens(
        IUniswapV2Router02 _uniswapV2Router,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) internal returns (uint256 amountIn, uint256 amountOut) {
        address[] memory path = _returnUniswapV2Path(_fromToken, _toToken);

        uint256[] memory amounts = _uniswapV2Router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );

        // Return the first item and the last item, so that it adheres to the path length
        return (amounts[0], amounts[path.length - 1]);
    }

    /// @dev Simple wrapper for the swapExactETHForTokens uniswap V2 function
    function _swapExactETHForTokens(
        IUniswapV2Router02 _uniswapV2Router,
        IERC20 _token,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) internal returns (uint256 amountIn, uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(_token);

        uint256[] memory amounts = _uniswapV2Router.swapExactETHForTokens{
            value: _amountIn
        }(_amountOutMin, path, _to, block.timestamp);

        return (amounts[0], amounts[1]);
    }

    /// @dev Simple wrapper for the swapExactTokensForETH uniswap V2 function
    function _swapExactTokensForETH(
        IUniswapV2Router02 _uniswapV2Router,
        IERC20 _token,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) internal returns (uint256 amountIn, uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = address(WETH);

        uint256[] memory amounts = _uniswapV2Router.swapExactTokensForETH(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );

        return (amounts[0], amounts[1]);
    }
}