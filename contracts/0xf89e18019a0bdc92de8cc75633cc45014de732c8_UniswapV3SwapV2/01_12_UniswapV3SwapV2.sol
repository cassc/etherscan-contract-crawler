// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/IPriceProvider.sol";

struct PricePath {
    IUniswapV3Pool pool;
    // if target/interim token is token0, then TRUE
    bool token0IsInterim;
}

/// @dev UniswapV3Swap IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
///         NOTE THAT SWAP DONE BY THIS CONTRACT MIGHT NOT BE OPTIMISED, WE ARE NOT USING SLIPPAGE AND YOU CAN LOSE
///         MONEY BY USING IT.
contract UniswapV3SwapV2 is ISwapper {
    bytes4 constant private _POOLS_SELECTOR = bytes4(keccak256("pools(address)"));

    ISwapRouter public immutable router;

    error RouterIsZero();
    error PoolNotSet();

    constructor (address _router) {
        if (_router == address(0)) revert RouterIsZero();

        router = ISwapRouter(_router);
    }

    /// @inheritdoc ISwapper
    function swapAmountIn(
        address,
        address,
        uint256 _amount,
        address _priceProvider,
        address _siloAsset
    ) external override returns (uint256 amountOut) {
        PricePath[] memory pricePath = fetchPricePath(_priceProvider, _siloAsset);
        bytes memory path = createPath(pricePath);
        return _swapAmountIn(path, _amount);
    }

    /// @inheritdoc ISwapper
    function swapAmountOut(
        address,
        address,
        uint256 _amountOut,
        address _priceProvider,
        address _siloAsset
    ) external override returns (uint256 amountIn) {
        PricePath[] memory pricePath = fetchPricePath(_priceProvider, _siloAsset);
        bytes memory path = createPath(pricePath);
        return _swapAmountOut(path, _amountOut);
    }

    /// @inheritdoc ISwapper
    function spenderToApprove() external view override returns (address) {
        return address(router);
    }

    /// @dev It will fetch price path for `_asset`, see UniswapV3PriceProvider.PricePath
    function fetchPricePath(address _priceProvider, address _asset)
        public
        view
        returns (PricePath[] memory pricePath)
    {
        bytes memory callData = abi.encodeWithSelector(_POOLS_SELECTOR, _asset);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = _priceProvider.staticcall(callData);
        if (!success) revert PoolNotSet();

        pricePath = abi.decode(data, (PricePath[]));
    }

    /// @param _pricePath asset price path, see UniswapV3PriceProvider.PricePath
    /// @return path The path is a sequence of (tokenAddress - fee - tokenAddress), which are the variables needed to
    /// compute each pool contract address in our sequence of swaps. The multihop swap router code will automatically
    /// find the correct pool with these variables, and execute the swap needed within each pool in our sequence.
    /// see https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps#input-parameters
    function createPath(PricePath[] memory _pricePath)
        public
        view
        returns (bytes memory path)
    {
        uint256 i;

        while (i < _pricePath.length) {
            (address token0, address token1) = (_pricePath[i].pool.token0(), _pricePath[i].pool.token1());
            (address from, address target) = _pricePath[i].token0IsInterim ? (token1, token0) : (token0, token1);

            if (i == _pricePath.length - 1) {
                path = abi.encodePacked(path, from, _pricePath[i].pool.fee(), target);
            } else {
                path = abi.encodePacked(path, from, _pricePath[i].pool.fee());
            }

            unchecked {
                // we will not overflow because we stop at i == _pricePath.length
                i++;
            }
        }
    }

    function _swapAmountIn(bytes memory _path, uint256 _amountIn) internal returns (uint256 amountOut) {
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
            path: _path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 1
        });

        return router.exactInput(params);
    }

    function _swapAmountOut(bytes memory _path, uint256 _amountOut) internal returns (uint256 amountOut) {
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: _path,
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: _amountOut,
            amountInMaximum: type(uint256).max
        });

        return router.exactOutput(params);
    }
}