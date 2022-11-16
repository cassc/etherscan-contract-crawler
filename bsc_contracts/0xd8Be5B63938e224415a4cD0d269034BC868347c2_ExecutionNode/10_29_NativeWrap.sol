// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "./Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract NativeWrap is Ownable, Initializable {
    address public nativeWrap;

    event NativeWrapUpdated(address nativeWrap);

    constructor(address _nativeWrap) {
        nativeWrap = _nativeWrap;
    }

    function initNativeWrap(address _nativeWrap) internal onlyInitializing {
        _setNativeWrap(_nativeWrap);
    }

    function setNativeWrap(address _nativeWrap) external onlyOwner {
        _setNativeWrap(_nativeWrap);
    }

    function _setNativeWrap(address _nativeWrap) private {
        nativeWrap = _nativeWrap;
        emit NativeWrapUpdated(_nativeWrap);
    }

    receive() external payable {}
}