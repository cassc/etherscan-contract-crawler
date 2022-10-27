// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./TradableCollection.sol";


contract TradableCollectionFactory {

    event Created(address creator, address collection, uint uuid);

    function create(
        string memory name,
        string memory symbol,
        uint howManyTokens,
        uint supplyPerToken,
        string memory baseURI,
        uint24 royaltiesBasispoints,
        uint uuid
    ) public returns (address) {
        TradableCollection instance = new TradableCollection(
            name,
            symbol,
            howManyTokens,
            supplyPerToken,
            baseURI,
            msg.sender,
            royaltiesBasispoints
        );
        emit Created(msg.sender, address(instance), uuid);
        return address(instance);
    }
}