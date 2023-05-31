// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MinimalForwarderUpgradeable} from "@openzeppelin/contracts-upgradeable/metatx/MinimalForwarderUpgradeable.sol";

contract NiftyKitForwarder is MinimalForwarderUpgradeable {
    function initialize() public initializer {
        __MinimalForwarder_init();
    }
}