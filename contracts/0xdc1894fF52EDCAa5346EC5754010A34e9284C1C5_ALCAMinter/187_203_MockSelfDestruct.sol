// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/proxy/ProxyInternalUpgradeLock.sol";
import "contracts/libraries/proxy/ProxyInternalUpgradeUnlock.sol";

/// @custom:salt MockSelfDestruct
contract MockSelfDestruct is ProxyInternalUpgradeLock, ProxyInternalUpgradeUnlock {
    address internal _factory;
    uint256 public v;
    uint256 public immutable i;

    constructor(uint256 _i, bytes memory) {
        i = _i;
        _factory = msg.sender;
    }

    function getFactory() external view returns (address) {
        return _factory;
    }

    function setV(uint256 _v) public {
        v = _v;
    }

    function lock() public {
        __lockImplementation();
    }

    function unlock() public {
        __unlockImplementation();
    }

    function setFactory(address factory_) public {
        _factory = factory_;
    }
}