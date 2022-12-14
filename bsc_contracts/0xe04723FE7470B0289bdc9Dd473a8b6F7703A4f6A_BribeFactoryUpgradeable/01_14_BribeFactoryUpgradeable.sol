// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IBribeFactory.sol";
import '../InternalBribe.sol';
import '../ExternalBribe.sol';


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BribeFactoryUpgradeable is IBribeFactory, OwnableUpgradeable {
    address public last_internal_bribe;
    address public last_external_bribe;

    constructor() {}

    function initialize() initializer  public {
        __Ownable_init();
    }

    function createInternalBribe(address[] memory allowedRewards) external returns (address) {
        last_internal_bribe = address(new InternalBribe(msg.sender, allowedRewards));
        return last_internal_bribe;
    }

    function createExternalBribe(address[] memory allowedRewards) external returns (address) {
        last_external_bribe = address(new ExternalBribe(msg.sender, allowedRewards));
        return last_external_bribe;
    }
}