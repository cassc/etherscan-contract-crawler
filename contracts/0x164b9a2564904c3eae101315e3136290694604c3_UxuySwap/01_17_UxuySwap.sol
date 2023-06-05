//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./interfaces/ISwapAdapter.sol";
import "./interfaces/ISwap.sol";
import "./libraries/BrokerBase.sol";
import "./libraries/SafeNativeAsset.sol";
import "./libraries/SafeERC20.sol";

contract UxuySwap is ISwap, BrokerBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    function getAmountIn(
        bytes4 providerID,
        address[] memory path,
        uint256 amountOut
    ) external override returns (uint256, bytes memory) {
        return _getAdapter(providerID).getAmountIn(path, amountOut);
    }

    function getAmountOut(
        bytes4 providerID,
        address[] memory path,
        uint256 amountIn
    ) external override returns (uint256, bytes memory) {
        return _getAdapter(providerID).getAmountOut(path, amountIn);
    }

    function getAmountInView(
        bytes4 providerID,
        address[] memory path,
        uint256 amountOut
    ) public view override returns (uint256 amountIn, bytes memory swapData) {
        return _getAdapter(providerID).getAmountInView(path, amountOut);
    }

    function getAmountOutView(
        bytes4 providerID,
        address[] memory path,
        uint256 amountIn
    ) public view override returns (uint256 amountOut, bytes memory swapData) {
        return _getAdapter(providerID).getAmountOutView(path, amountIn);
    }

    function swap(
        SwapParams calldata params
    ) external whenNotPaused onlyAllowedCaller noDelegateCall returns (uint256 amountOut) {
        ISwapAdapter adapter = _getAdapter(params.providerID);
        address tokenOut = params.path[params.path.length - 1];
        uint256 balanceBefore = 0;
        if (tokenOut.isNativeAsset()) {
            balanceBefore = params.recipient.balance;
        } else {
            balanceBefore = IERC20(tokenOut).balanceOf(params.recipient);
        }
        adapter.swap(
            ISwapAdapter.SwapParams({
                path: params.path,
                amountIn: params.amountIn,
                minAmountOut: params.minAmountOut,
                recipient: params.recipient,
                data: params.data
            })
        );
        if (tokenOut.isNativeAsset()) {
            amountOut = params.recipient.balance - balanceBefore;
        } else {
            amountOut = IERC20(tokenOut).balanceOf(params.recipient) - balanceBefore;
        }
        require(amountOut >= params.minAmountOut, "UxuySwap: swapped amount less than minAmountOut");
    }

    function _getAdapter(bytes4 providerID) internal view returns (ISwapAdapter) {
        address provider = _getProvider(providerID);
        require(provider != address(0), "UxuySwap: provider not found");
        return ISwapAdapter(provider);
    }
}