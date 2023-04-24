// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../interfaces/IPeripheryState.sol";
import "../storage/NativeRouterStorage.sol";

abstract contract PeripheryState is IPeripheryState {
    address public override factory;
    address public override WETH9;
    address payable public weth9Unwrapper;

    function initializeState(address _factory, address _WETH9) internal {
        require(_factory != address(0), "PeripheryState: factory address cannot be 0");
        require(_WETH9 != address(0), "PeripheryState: WETH9 address cannot be 0");
        factory = _factory;
        WETH9 = _WETH9;
    }

    function setWeth9Unwrapper(address payable _weth9Unwrapper) virtual public;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}