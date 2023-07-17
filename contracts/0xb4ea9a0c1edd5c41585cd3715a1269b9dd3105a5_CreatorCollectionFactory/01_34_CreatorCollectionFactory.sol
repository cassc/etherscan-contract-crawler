// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./CreatorCollection.sol";

contract CreatorCollectionFactory {
    address public immutable implementation;

    event CreatorCollectionCreated(address indexed collection);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createCollection(
        string calldata baseURI,
        string calldata contractName,
        string calldata tokenSymbol,
        address owner
    ) external returns (address) {
        address clone = Clones.clone(implementation);
        CreatorCollection(clone).initialize(
            baseURI,
            contractName,
            tokenSymbol,
            owner
        );
        emit CreatorCollectionCreated(clone);
        return clone;
    }
}