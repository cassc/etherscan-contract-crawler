// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "./openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ICapsuleFactory.sol";

abstract contract CapsuleFactoryStorage is ICapsuleFactory {
    uint256 public capsuleCollectionTax;
    address public taxCollector;
    address public capsuleMinter;
    address[] public capsules;

    /**
     * @notice Is a given address a Capsule Collection?
     * Capsule Collection address -> bool mapping
     */
    mapping(address => bool) public isCapsule;

    // What Capsule Collections does an address have ownership of?
    // Capsule Collection owner -> Capsule collection AddressSet mapping
    mapping(address => EnumerableSet.AddressSet) internal capsulesOf;

    // List of addresses which can interact with the Capsule protocol without paying creationTax
    EnumerableSet.AddressSet internal whitelist;

    // List of addresses prohibited from interacting with the Capsule protocol
    EnumerableSet.AddressSet internal blacklist;
}