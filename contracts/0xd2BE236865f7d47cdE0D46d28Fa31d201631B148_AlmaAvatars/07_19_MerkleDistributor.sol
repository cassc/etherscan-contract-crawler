// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract MerkleDistributor is Initializable, OwnableUpgradeable {
    bytes32 public root;

    function __MerkleDistributor_init(bytes32 _root) internal onlyInitializing {
        root = _root;
    }

    function setRoot(bytes32 _root) external virtual onlyOwner {
        root = _root;
    }

    /// @dev UUPSUpgradeable storage gap
    uint256[49] private __gap;
}