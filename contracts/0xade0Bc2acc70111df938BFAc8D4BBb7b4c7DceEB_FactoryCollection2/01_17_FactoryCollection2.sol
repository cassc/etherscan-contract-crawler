// SPDX-License-Identifier: ISC
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CollectionRoyalty.sol";

contract FactoryCollection2 is Ownable {
    // events
    event NewCollection(address indexed collection, address indexed owner, uint indexed deployIndex);

    // deployed marketplaces
    mapping (uint => address) public collections;
    uint public collectionsCounter;

    mapping (address => bool) public deployersCollection;

    modifier onlyDeployers() {
        require(deployersCollection[msg.sender] == true || msg.sender == owner(), "CollectionRoyaltyFactory: only deployers or owner can call this function");
        _;
    }

    /**
     * @notice Constructor
     */
    constructor () {}

    /**
     * @notice Deploy new Collection
     * @param _owner Owner of the new collection contract.
     * @param _name Name of the new collection contract
     * @param _symbol Symbol of the new collection contract
     * @param _baseURI Prefix of the token URI
    */
    function deployCollectionRoyalty(address _owner, string memory _name, string memory _symbol, string memory _baseURI,
       uint _maxSupply, uint96 _baseRoyalty, address _treasury) external onlyDeployers {

        CollectionRoyalty collectionRoyalty = new CollectionRoyalty(_name, _symbol, _maxSupply);
        collectionRoyalty.setBaseURI(_baseURI);
 
        collectionRoyalty.setDefaultRoyalty(_treasury, _baseRoyalty);
        collectionRoyalty.transferOwnership(_owner);

        collections[collectionsCounter] = address(collectionRoyalty);
        collectionsCounter += 1;

        emit NewCollection(address(collectionRoyalty), _owner, collectionsCounter - 1);
    }

    function addDeployers(address _address) external onlyOwner {
        require(deployersCollection[_address] == false, "CollectionRoyaltyFactory: address already added");

        deployersCollection[_address] = true;
    }

    function removeDeployers(address _address) external onlyOwner {
        require(deployersCollection[_address] == true, "CollectionRoyaltyFactory: address not already added");

        deployersCollection[_address] = false;
    }
}