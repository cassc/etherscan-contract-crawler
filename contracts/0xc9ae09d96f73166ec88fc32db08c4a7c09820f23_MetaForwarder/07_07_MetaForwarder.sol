// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/metatx/MinimalForwarderUpgradeable.sol";

contract MetaForwarder is MinimalForwarderUpgradeable {
    function initialize() external initializer {
        __EIP712_init_unchained("TellerBNPLMetaForwarder", "0.1.0");
    }
}