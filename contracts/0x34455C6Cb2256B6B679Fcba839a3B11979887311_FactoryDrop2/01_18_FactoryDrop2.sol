// SPDX-License-Identifier: ISC
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DropCollection.sol";

contract FactoryDrop2 is Ownable {
    // events
    event NewCollectionMinterRoyalty(address indexed collection, address indexed owner, uint indexed deployIndex);

    // deployed collection
    mapping (uint => address) public collections;
    uint public collectionsCounter;

    mapping (address => bool) public deployersCollection;

    modifier onlyDeployers() {
        require(deployersCollection[msg.sender] == true || msg.sender == owner(), "CollectionMinterRoyaltyFactory: only deployers or owner can call this function");
        _;
    }

    /**
     * @notice Deploy new Collection with royalty
     * @param _owner Owner of the new collection contract.
     * @param _name Name of the new collection contract
     * @param _symbol Symbol of the new collection contract
     * @param _baseURI Prefix of the token URI
     * @param _tokenURI Suffix of the token URI
     * @param _maxSupply max supply for token, set 0 means no maxSupply
     * @param _mintPrice price for mint in ETH, 18 decimals
    */
    function deployCollectionMinterRoyalty(address _owner, string memory _name, string memory _symbol, string memory _baseURI,
        string memory _tokenURI, uint _maxSupply, uint _mintPrice, uint96 _baseRoyalty, bool _vipTokenMode,
        bool _whitelistedMode, uint _discountPercentage, address _treasury) external onlyDeployers {

        DropCollection collectionMinterRoyalty = new DropCollection(_name, _symbol, _maxSupply, _mintPrice,
        _vipTokenMode, _discountPercentage,_whitelistedMode);

        collectionMinterRoyalty.setBaseURI(_baseURI);
        collectionMinterRoyalty.setSuffixURI(_tokenURI);
        collectionMinterRoyalty.setDefaultRoyalty(_treasury, _baseRoyalty);

        collectionMinterRoyalty.transferOwnership(_owner);

        collections[collectionsCounter] = address(collectionMinterRoyalty);
        collectionsCounter += 1;

        emit NewCollectionMinterRoyalty(address(collectionMinterRoyalty), _owner, collectionsCounter - 1);
    }

    function addDeployers(address _address) external onlyOwner {
        require(deployersCollection[_address] == false, "CollectionMinterRoyaltyFactory: address already added");

        deployersCollection[_address] = true;
    }

    function removeDeployers(address _address) external onlyOwner {
        require(deployersCollection[_address] == true, "CollectionMinterRoyaltyFactory: address not already added");

        deployersCollection[_address] = false;
    }
}