// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IRDNRegistry} from "./interfaces/IRDNRegistry.sol";

contract RDNOwnable {
    address public registry;
    uint public ownerId;

    function initRDNOwnable(address _registry, uint _ownerId) internal {
        registry = _registry;
        require(IRDNRegistry(registry).isValidUser(_ownerId));
        ownerId = _ownerId;
    }

    // modifier RDNOnly(address _sender) {
    //     require(isRegistered)
    // }

    modifier onlyRDNOwner(address _userAddress) {
        require(IRDNRegistry(registry).getUserIdByAddress(_userAddress) == ownerId, "RDNOwnable: access denied");
        _;
    }

}