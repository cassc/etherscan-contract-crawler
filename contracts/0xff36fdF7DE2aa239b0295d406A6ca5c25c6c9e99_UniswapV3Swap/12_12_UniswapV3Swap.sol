// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/IPriceProvider.sol";

/// @dev UniswapV3Swap IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
///         NOTE THAT SWAP DONE BY THIS CONTRACT MIGHT NOT BE OPTIMISED, WE ARE NOT USING SLIPPAGE AND YOU CAN LOSE
///         MONEY BY USING IT.
contract UniswapV3Swap is ISwapper {
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
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _priceProvider,
        address _siloAsset
    ) external override returns (uint256 amountOut) {
        uint24 fee = resolveFee(_priceProvider, _siloAsset);
        return _swapAmountIn(_tokenIn, _tokenOut, _amount, fee);
    }

    /// @inheritdoc ISwapper
    function swapAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut,
        address _priceProvider,
        address _siloAsset
    ) external override returns (uint256 amountIn) {
        uint24 fee = resolveFee(_priceProvider, _siloAsset);
        return _swapAmountOut(_tokenIn, _tokenOut, _amountOut, fee);
    }

    /// @inheritdoc ISwapper
    function spenderToApprove() external view override returns (address) {
        return address(router);
    }

    function resolveFee(address _priceProvider, address _asset) public view returns (uint24 fee) {
        bytes memory callData = abi.encodeWithSelector(_POOLS_SELECTOR, _asset);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = _priceProvider.staticcall(callData);
        if (!success) revert PoolNotSet();

        IUniswapV3Pool pool = IUniswapV3Pool(abi.decode(data, (address)));
        fee = pool.fee();
    }

    function pathToBytes(address[] memory path, uint24[] memory fees) public pure returns (bytes memory bytesPath) {
        for (uint256 i = 0; i < path.length; i++) {
            bytesPath = i == fees.length
            ? abi.encodePacked(bytesPath, path[i])
            : abi.encodePacked(bytesPath, path[i], fees[i]);
        }
    }

    function _swapAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint24 _fee
    ) internal returns (uint256 amountOut) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 1,
            sqrtPriceLimitX96: 0
        });

        return router.exactInputSingle(params);
    }

    function _swapAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut,
        uint24 _fee
    ) internal returns (uint256 amountOut) {
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: _amountOut,
            amountInMaximum: type(uint256).max,
            sqrtPriceLimitX96: 0
        });

        return router.exactOutputSingle(params);
    }
}