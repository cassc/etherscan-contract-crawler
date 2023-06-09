//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../interfaces/swaps/curve/IAddressProvider.sol";
import "../interfaces/swaps/curve/IRegistry.sol";
import "../interfaces/swaps/curve/IExchange.sol";
import "../interfaces/swaps/curve/ICurvePool.sol";
import "../libraries/SwapAdapterBase.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/SafeNativeAsset.sol";

contract CurveSwapAdapter is SwapAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    IAddressProvider private immutable _addressProvider;
    IRegistry private immutable _registry;
    IExchange private immutable _curve;

    constructor(address addressProvider) {
        _addressProvider = IAddressProvider(addressProvider);
        _registry = IRegistry(_addressProvider.get_registry());
        _curve = IExchange(_addressProvider.get_address(2));
        _setWrappedNativeAsset(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }

    function getAmountOutView(
        address[] memory path,
        uint256 amountIn
    ) public view override returns (uint256 amountOut, bytes memory swapData) {
        swapData = "";
        _convertPath(path);
        try _curve.get_best_rate(path[0], path[path.length - 1], amountIn) returns (address pool, uint256 amount) {
            amountOut = amount;
            swapData = abi.encode(pool);
        } catch {
            amountOut = 0;
        }
    }

    function swap(
        SwapParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall returns (uint256 amountOut) {
        address pool = abi.decode(params.data, (address));
        address tokenIn = params.path[0];
        address tokenOut = params.path[params.path.length - 1];
        uint256 value = 0;
        if (tokenIn.isNativeAsset()) {
            tokenIn = WrappedNativeAsset();
            value = params.amountIn;
        }
        if (tokenOut.isNativeAsset()) {
            tokenOut = WrappedNativeAsset();
        }
        if (tokenIn != WrappedNativeAsset()) {
            IERC20(tokenIn).safeApproveToMax(address(_curve), params.amountIn);
        }
        uint256[2] memory poolCoins = _registry.get_n_coins(pool);
        require(poolCoins[0] > 0, "CurveSwapAdapter: invalid pool");
        try
            _curve.exchange{value: value}(
                pool,
                tokenIn,
                tokenOut,
                params.amountIn,
                params.minAmountOut,
                params.recipient
            )
        returns (uint256 amount) {
            amountOut = amount;
        } catch {
            if (tokenIn != _wrappedNativeAsset) {
                IERC20(tokenIn).safeApproveToMax(pool, params.amountIn);
            }
            (int128 indexIn, int128 indexOut) = _getTokensIndex(pool, poolCoins[0], tokenIn, tokenOut);
            amountOut = ICurvePool(pool).exchange{value: value}(
                indexIn,
                indexOut,
                params.amountIn,
                params.minAmountOut,
                params.recipient
            );
        }
    }

    function _getTokensIndex(
        address pool,
        uint256 poolCoins,
        address tokenIn,
        address tokenOut
    ) internal returns (int128 indexIn, int128 indexOut) {
        indexIn = -1;
        indexOut = -1;
        for (uint256 i = 0; i < poolCoins; i++) {
            try ICurvePool(pool).coins(i) returns (address token) {
                if (token == tokenIn) {
                    indexIn = int128(uint128(i));
                }
                if (token == tokenOut) {
                    indexOut = int128(uint128(i));
                }
            } catch {}
        }
        require(indexIn >= 0 && indexOut >= 0, "CurveSwapAdapter: token not found in pool");
    }
}