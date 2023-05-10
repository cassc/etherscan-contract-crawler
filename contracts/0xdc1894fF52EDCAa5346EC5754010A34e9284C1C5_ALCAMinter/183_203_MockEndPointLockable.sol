// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/Proxy.sol";
import "contracts/libraries/proxy/ProxyInternalUpgradeLock.sol";
import "contracts/libraries/proxy/ProxyInternalUpgradeUnlock.sol";
import "contracts/libraries/proxy/ProxyImplementationGetter.sol";

interface IMockEndPointLockable {
    function addOne() external;

    function addTwo() external;

    function factory() external returns (address);

    function i() external view returns (uint256);
}

/// @custom:salt MockEndPointLockable
contract MockEndPointLockable is
    ProxyInternalUpgradeLock,
    ProxyInternalUpgradeUnlock,
    ProxyImplementationGetter,
    IMockEndPointLockable
{
    error Unauthorized();
    address private immutable _factory;
    address public owner;
    uint256 public i;

    event AddedOne(uint256 indexed i);
    event AddedTwo(uint256 indexed i);
    event UpgradeLocked(bool indexed lock);
    event UpgradeUnlocked(bool indexed lock);

    modifier onlyOwner() {
        _requireAuth(msg.sender == owner);
        _;
    }

    constructor(address f) {
        _factory = f;
    }

    function addOne() public {
        i++;
        emit AddedOne(i);
    }

    function addTwo() public {
        i = i + 2;
        emit AddedTwo(i);
    }

    function poluteImplementationAddress() public {
        assembly ("memory-safe") {
            let implSlot := not(0x00)
            sstore(
                implSlot,
                or(
                    0xbabeffff15deffffbabeffff0000000000000000000000000000000000000000,
                    sload(implSlot)
                )
            )
        }
    }

    function upgradeLock() public {
        __lockImplementation();
        emit UpgradeLocked(true);
    }

    function upgradeUnlock() public {
        __unlockImplementation();
        emit UpgradeUnlocked(false);
    }

    function factory() public view returns (address) {
        return _factory;
    }

    function _requireAuth(bool isOk_) internal pure {
        if (!isOk_) {
            revert Unauthorized();
        }
    }
}