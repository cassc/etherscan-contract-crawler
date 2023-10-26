// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibClone} from "solady/utils/LibClone.sol";
import {WERC721} from "src/WERC721.sol";

/**
 * @title ERC721 wrapper factory contract.
 * @notice Deploy a WERC721 contract for any ERC721 collection.
 * @author kp (ppmoon69.eth)
 * @custom:contributor vectorized (vectorized.eth)
 * @custom:contributor pashov (pashov.eth)
 */
contract WERC721Factory {
    // Wrapped collection (i.e. WERC721) implementation address.
    WERC721 public immutable implementation = new WERC721();

    // Collection contract addresses mapped to their wrapped counterparts.
    mapping(address collection => address wrapper) public wrappers;

    // This emits when a new WERC721 contract is created.
    event CreateWrapper(address indexed collection, address indexed wrapper);

    error WrapperAlreadyCreated();

    /**
     * @notice Create a new WERC721 contract.
     * @param  collection  address  ERC721 collection contract address.
     * @return wrapper     address  Wrapped ERC721 contract address.
     */
    function create(address collection) external returns (address wrapper) {
        // Each collection should only have one WERC721 contract to avoid confusion.
        if (wrappers[collection] != address(0)) revert WrapperAlreadyCreated();

        // Clone the implementation with `collection` stored as an immutable arg.
        wrapper = LibClone.clone(
            address(implementation),
            abi.encodePacked(collection)
        );

        wrappers[collection] = wrapper;

        emit CreateWrapper(collection, wrapper);
    }
}