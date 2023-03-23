// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IRDNRegistry} from "./interfaces/IRDNRegistry.sol";

contract RDNOwnable {
    address public registry;
    uint public ownerId;

    function initRDNOwnable(address _registry, uint _ownerId) internal {
        registry = _registry;
        require(IRDNRegistry(registry).isValidUser(_ownerId));
        ownerId = _ownerId;
    }

    modifier onlyRDNOwner(address _userAddress) {
        require(isRDNOwner(_userAddress), "RDNOwnable: access denied");
        _;
    }

    modifier onlyActiveRDNOwner(address _userAddress) {
        require(isActiveRDNOwner(_userAddress), "RDNOwnable: access denied");
        _;
    }

    function isRDNOwner(address _userAddress) public view returns(bool) {
        return(IRDNRegistry(registry).getUserIdByAddress(_userAddress) == ownerId);
    }

    function isActiveRDNOwner(address _userAddress) public view returns(bool) {
        IRDNRegistry registryInterface = IRDNRegistry(registry);
        return(registryInterface.isActive(registryInterface.getUserIdByAddress(_userAddress)));
    }

}