// SPDX-License-Identifier: MIT

/*

  WyvernOwnableDelegateProxy

*/

pragma solidity ^0.8.13;

import "./proxy/OwnedUpgradeabilityProxy.sol";

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes memory data) {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);

        (bool success,) = initialImplementation.delegatecall(data);
        require(success, "OwnableDelegateProxy failed implementation");
    }

}