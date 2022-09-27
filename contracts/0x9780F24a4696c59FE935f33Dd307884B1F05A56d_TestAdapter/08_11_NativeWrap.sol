// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title A codec registry that maps swap function selectors to corresponding codec addresses
 * @author Padoriku
 */
abstract contract NativeWrap is Ownable {
    address public nativeWrap;

    event NativeWrapUpdated(address nativeWrap);

    constructor(address _nativeWrap) {
        require(_nativeWrap != address(0), "zero native wrap");
        nativeWrap = _nativeWrap;
    }

    function setNativeWrap(address _nativeWrap) external onlyOwner {
        nativeWrap = _nativeWrap;
    }

    receive() external payable {}
}