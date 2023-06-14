//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../interfaces/bridges/IXYBridge.sol";
import "../libraries/BridgeAdapterBase.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

contract XYBridgeAdapter is BridgeAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    address private immutable _xyBridge;
    mapping(bytes4 => bool) private _allowedSelectors;

    constructor(address xyBridge) {
        _xyBridge = xyBridge;
        _allowedSelectors[0x4039c8d0] = true; // swap
        _allowedSelectors[0x2aac3cac] = true; // swapWithReferrer
        _allowedSelectors[0xd28240fd] = true; // singleChainSwap
        _allowedSelectors[0xbb7f50ea] = true; // singleChainSwapWithReferrer
    }

    function supportSwap() external pure returns (bool) {
        return true;
    }

    function bridge(
        BridgeParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall returns (uint256, uint256) {
        bool success;
        bytes memory data;
        if (!params.tokenIn.isNativeAsset()) {
            IERC20(params.tokenIn).safeApproveToMax(_xyBridge, params.amountIn);
        }
        bytes4 selector = bytes4(params.data[:4]);
        require(_allowedSelectors[selector], "XYBridgeAdapter: illegal function selector");

        (success, data) = _xyBridge.call{value: params.tokenIn.isNativeAsset() ? params.amountIn : 0}(params.data);
        require(success, string(abi.encodePacked("XYBridgeAdapter: call xybridge failed: ", data)));

        return (0, 0);
    }
}