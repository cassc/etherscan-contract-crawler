//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./AdapterBase.sol";
import "../interfaces/ISwapAdapter.sol";
import "../interfaces/tokens/IWrappedNativeAsset.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

abstract contract SwapAdapterBase is ISwapAdapter, AdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    // wrapped native asset address for swap in current chain
    address internal _wrappedNativeAsset;

    // @dev handle swap between native asset and wrapped native asset
    // @notice if swapped between native asset and wrapped native asset, the modified function will return default value
    modifier handleWrap(SwapParams calldata params) {
        address tokenIn = params.path[0];
        address tokenOut = params.path[params.path.length - 1];
        if (tokenIn.isNativeAsset() && tokenOut == WrappedNativeAsset()) {
            _wrapNativeAsset(params.amountIn, params.recipient);
            return;
        } else if (tokenIn == WrappedNativeAsset() && tokenOut.isNativeAsset()) {
            _unwrapNativeAsset(params.amountIn, params.recipient);
            return;
        }
        _;
    }

    function getAmountIn(
        address[] memory path,
        uint256 amountOut
    ) external virtual override returns (uint256, bytes memory) {
        return getAmountInView(path, amountOut);
    }

    function getAmountOut(
        address[] memory path,
        uint256 amountIn
    ) external virtual override returns (uint256, bytes memory) {
        return getAmountOutView(path, amountIn);
    }

    function getAmountInView(address[] memory, uint256) public view virtual returns (uint256, bytes memory) {
        revert("SwapAdapterBase: not supported");
    }

    function getAmountOutView(address[] memory, uint256) public view virtual returns (uint256, bytes memory) {
        revert("SwapAdapterBase: not supported");
    }

    // @dev get wrapped native asset address for swap in current chain
    function WrappedNativeAsset() public view virtual returns (address) {
        return _wrappedNativeAsset;
    }

    // @dev transfer native asset to recipient in wrapped token
    function _wrapNativeAsset(uint256 amount, address recipient) internal {
        require(address(this).balance >= amount, "SwapAdapterBase: not enough native asset in transaction");
        if (amount > 0) {
            IWrappedNativeAsset wna = IWrappedNativeAsset(WrappedNativeAsset());
            wna.deposit{value: amount}();
            IERC20(wna).safeTransfer(recipient, amount);
        }
    }

    // @dev transfer wrapped token to recipient in native asset
    function _unwrapNativeAsset(uint256 amount, address recipient) internal {
        IWrappedNativeAsset wna = IWrappedNativeAsset(WrappedNativeAsset());
        uint256 balance = wna.balanceOf(address(this));
        require(balance >= amount, "SwapAdapterBase: not enough native asset in transaction");
        if (amount > 0) {
            wna.withdraw(amount);
            recipient.safeTransfer(amount);
        }
    }

    // @dev set wrapped native asset address for swap in current chain
    function _setWrappedNativeAsset(address addr) internal {
        _wrappedNativeAsset = addr;
    }

    // @dev replace native asset address to wrapped token address
    function _convertPath(address[] memory path) internal view returns (address[] memory) {
        for (uint256 i = 0; i < path.length; i++) {
            if (path[i].isNativeAsset()) {
                path[i] = WrappedNativeAsset();
            }
        }
        return path;
    }
}