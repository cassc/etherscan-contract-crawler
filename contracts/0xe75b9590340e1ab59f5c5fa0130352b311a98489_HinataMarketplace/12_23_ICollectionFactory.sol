// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ICollectionFactory {
    struct Royalty {
        address beneficiary;
        uint256 percentage;
        bool deleted;
    }

    struct Collection {
        address owner;
        address collection;
        Royalty[] royalties;
        uint256 royaltySum;
        bool is721;
    }

    event CollectionWhitelisted(
        uint256 indexed id,
        address indexed owner,
        address indexed collection,
        Royalty[] royalties,
        bool is721
    );

    function getCollection(address collection) external view returns (Collection memory);

    function getCollectionRoyalties(address collection) external view returns (Royalty[] memory);
}