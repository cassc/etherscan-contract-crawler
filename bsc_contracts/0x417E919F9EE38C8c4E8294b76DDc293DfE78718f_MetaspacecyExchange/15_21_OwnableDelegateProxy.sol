// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnedUpgradeabilityProxy.sol";

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {
    constructor(
        address owner,
        address initialImplementation,
        bytes memory callData
    ) {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success, ) = initialImplementation.delegatecall(callData);
        require(success);
    }
}