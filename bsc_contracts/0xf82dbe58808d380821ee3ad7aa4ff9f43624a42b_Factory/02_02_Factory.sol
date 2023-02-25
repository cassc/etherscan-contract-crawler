// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

contract Factory {
    event Cloned(address instance);

    function clone(address implementation) public {
        address instance = ClonesUpgradeable.clone(implementation);
        emit Cloned(instance);
    }
}