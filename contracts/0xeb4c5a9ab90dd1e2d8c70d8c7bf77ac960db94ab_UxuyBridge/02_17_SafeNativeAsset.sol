//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

library SafeNativeAsset {
    // native asset address
    address internal constant NATIVE_ASSET = address(0);

    function nativeAsset() internal pure returns (address) {
        return NATIVE_ASSET;
    }

    function isNativeAsset(address addr) internal pure returns (bool) {
        return addr == NATIVE_ASSET;
    }

    function safeTransfer(address recipient, uint256 amount) internal {
        require(recipient != address(0), "SafeNativeAsset: transfer to the zero address");
        (bool success, ) = recipient.call{value: amount}(new bytes(0));
        require(success, "SafeNativeAsset: safe transfer native assets failed");
    }
}