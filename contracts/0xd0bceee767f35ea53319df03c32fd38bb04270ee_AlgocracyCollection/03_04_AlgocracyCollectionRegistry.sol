// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

/// @title Algocracy Collection Registry
/// @author jolan.eth

abstract contract AlgocracyCollectionRegistry {
    struct Module {
        address NFT;
        address Prime;
        address Provider;
    }

    struct Meta {
        string name;
        string cover;
        string description;
        uint256 maxSupply;
        uint256 blockNumber;
    }

    struct Mint {
        bool isActive;
        bool isRandom;
        bool isAllowListed;
        uint256 maxQuantity;
        uint256 price;
    }

    struct Collection {
        Meta Data;
        Mint State;
        Module Contract;
    }

    uint256[2] public FIXED_NAME = [1,15];
    uint256[2] public FIXED_DESCRIPTION = [1,140];
    uint256[2] public FIXED_MAX_SUPPLY = [1,1000];

    uint256 collectionIndex;
    mapping(uint256 => Collection) CollectionRegistry;

    function getCollectionRegistryLength()
    public view returns (uint256) {
        return collectionIndex;
    }

    function getCollectionData(uint256 id)
    public view returns (Meta memory) {
        return CollectionRegistry[id].Data;
    }

    function getCollectionContract(uint256 id)
    public view returns (Module memory) {
        return CollectionRegistry[id].Contract;
    }

    function getCollectionState(uint256 id)
    public view returns (Mint memory) {
        return CollectionRegistry[id].State;
    }

    function getCollectionRegistry(uint256 id)
    public view returns (Collection memory) {
        return CollectionRegistry[id];
    }

    function setCollectionRegistration(
        address _NFT, address _Prime, address _Provider,
        string memory _name, string memory _cover, string memory _description,
        uint256 _maxSupply, uint256 _REGISTRY_IDENTIFIER
    ) internal {
        require(
            _maxSupply >= FIXED_MAX_SUPPLY[0] && _maxSupply <= FIXED_MAX_SUPPLY[1],
            "AlgocracyCollectionRegistry::setCollectionRegistration() - _max supply is out of bound"
        );

        require(
            bytes(_name).length >= FIXED_NAME[0] && bytes(_name).length <= FIXED_NAME[1],
            "AlgocracyCollectionRegistry::setCollectionRegistration() - _name is out of bound"
        );

        require(
            bytes(_description).length >= FIXED_DESCRIPTION[0] && bytes(_description).length <= FIXED_DESCRIPTION[1],
            "AlgocracyCollectionRegistry::setCollectionRegistration() - _description is out of bound"
        );

        Module memory Contract = Module(
            _NFT, _Prime, _Provider
        );

        Meta memory Data = Meta(
            _name, _cover, _description, 
            _maxSupply, block.number
        );

        Mint memory State = Mint(
            false, false, false, 0, 0
        );

        Collection memory newCollection = Collection(
            Data, State, Contract
        );

        CollectionRegistry[_REGISTRY_IDENTIFIER] = newCollection;
    }
}