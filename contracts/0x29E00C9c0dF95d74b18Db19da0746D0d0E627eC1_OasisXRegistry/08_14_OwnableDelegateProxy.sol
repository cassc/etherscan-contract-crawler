//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./proxy/OwnedUpgradeabilityProxy.sol";

/**
 * @title OwnableDelegateProxy
 * @author OasisX Protocol | cryptoware.eth
 */
contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {
    constructor(
        address owner,
        address initialImplementation,
        bytes memory data
    ) {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success, ) = initialImplementation.delegatecall(data); /* solium-disable-line */
        require(success, "OwnableDelegateProxy failed implementation");
    }
}