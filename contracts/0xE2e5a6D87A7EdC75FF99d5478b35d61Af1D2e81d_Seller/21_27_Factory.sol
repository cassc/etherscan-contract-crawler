// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./utils/Address.sol";
import "./utils/Structs.sol";
import "./Collection.sol";
import "./Store.sol";

struct CollectionData {
  string name;
  string symbol;
  string baseTokenURI;
  uint256 supply;
  address[] authorizedAddresses;
  bool mintL1Authorized;
}

contract Factory is Ownable {
  address public collectionTemplate;
  address public store;
  address public seller;
  mapping(address => bool) public isCollection;

  event CollectionCreated(
    string name,
    string symbol,
    address store,
    address seller,
    address collectionAddress
  );

  constructor(address _collectionTemplate) {
    collectionTemplate = _collectionTemplate;
  }

  function setStore(address _store, address _seller) external onlyOwner {
    store = _store;
    seller = _seller;
  }

  function setCollectionTemplate(address _collectionTemplate)
    external
    onlyOwner
  {
    collectionTemplate = _collectionTemplate;
  }

  function createCollection(
    CollectionData memory _collection,
    Sale[] memory _sales,
    address _owner
  ) external {
    require(store != address(0), "No store was set");
    require(seller != address(0), "No seller was set");
    address collectionAddress = Clones.clone(collectionTemplate);
    string memory strAddress = Address.toAsciiString(collectionAddress);
    string memory baseTokenURI = string(
      abi.encodePacked(_collection.baseTokenURI, "/0x", strAddress)
    );

    isCollection[collectionAddress] = true;
    Collection(collectionAddress).init(
      _collection.name,
      _collection.symbol,
      baseTokenURI,
      seller,
      _collection.supply,
      _collection.authorizedAddresses,
      _owner
    );
    Store(store).addCollection(collectionAddress, _collection.mintL1Authorized);
    if (_sales.length > 0) {
      Store(store).addSales(collectionAddress, _sales);
    }
    emit CollectionCreated(
      _collection.name,
      _collection.symbol,
      store,
      seller,
      collectionAddress
    );
  }
}