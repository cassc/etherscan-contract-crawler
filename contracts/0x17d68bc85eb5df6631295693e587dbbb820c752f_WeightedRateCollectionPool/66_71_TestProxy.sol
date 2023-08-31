// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Test proxy for peripheral contracts
 * @author MetaStreet Labs
 */
contract TestProxy is Proxy {
    /**
     * @dev Space for implementation storage
     */
    uint256[128] private __reserved;

    /**
     * @dev Implementation contract
     */
    address private _impl;

    /**
     * @notice TestProxy constructor
     * @param implementation Implementation contract
     * @param data Initialization calldata
     */
    constructor(address implementation, bytes memory data) {
        _impl = implementation;
        Address.functionDelegateCall(implementation, data);
    }

    /*
     * @dev Proxy implementation address hook
     */
    function _implementation() internal view virtual override returns (address) {
        return _impl;
    }
}