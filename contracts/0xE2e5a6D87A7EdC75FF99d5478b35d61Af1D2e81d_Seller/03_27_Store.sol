// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Factory.sol";
import "./Collection.sol";
import "./features/Authorizable.sol";
import "./features/Stoppable.sol";
import "./utils/Parsing.sol";
import "./utils/Structs.sol";

struct CollectionStatus {
  bool isBlacklisted;
  bool mintL1Authorized;
}

contract Store is Stoppable, Authorizable {
  Factory public factory;
  mapping(address => CollectionStatus) public collection;
  mapping(address => Sale[]) public sales;

  event SalesAdded(address collection, Sale[] sales);
  event CollectionAdded(address collection);
  event PriceChanged(
    address collection,
    uint256 saleId,
    uint256 oldValue,
    uint256 newValue
  );
  event SupplyChanged(
    address collection,
    uint256 saleId,
    uint256 oldValue,
    uint256 newValue
  );
  event WhitelistChanged(
    address collection,
    uint256 saleId,
    bytes32 oldValue,
    bytes32 newValue
  );
  event CollectionBlacklisted(address collection, bool blacklisted);

  modifier storeOrCollectionAuthorized(address _collection) {
    require(
      isAuthorized(msg.sender, _collection),
      "UNAUTHORIZED: Sender is not authorized"
    );
    _;
  }

  modifier validCollection(address _collection) {
    validateCollection(_collection);
    _;
  }

  constructor(address _factory) {
    factory = Factory(_factory);
    authorize(_factory, true);
    authorize(msg.sender, true);
  }

  function addCollection(address _collection, bool _mintL1Authorized)
    external
    nonStopped
  {
    require(
      factory.isCollection(_collection),
      "TRANSACTION: Invalid collection"
    );
    collection[_collection].mintL1Authorized = _mintL1Authorized;

    emit CollectionAdded(_collection);
  }

  function addSales(address _collection, Sale[] memory _sales)
    external
    nonStopped
    validCollection(_collection)
    storeOrCollectionAuthorized(_collection)
  {
    for (uint256 i = 0; i < _sales.length; i++) {
      _addSale(_collection, _sales[i]);
    }

    emit SalesAdded(_collection, _sales);
  }

  function blacklistCollection(address _collection, bool _blacklist)
    external
    nonStopped
    onlyOwner
  {
    collection[_collection].isBlacklisted = _blacklist;
    emit CollectionBlacklisted(_collection, _blacklist);
  }

  function authorizeMintL1(address _collection, bool _authorize)
    external
    nonStopped
    validCollection(_collection)
    storeOrCollectionAuthorized(_collection)
  {
    collection[_collection].mintL1Authorized = _authorize;
  }

  function setSaleActive(
    address _collection,
    uint256 _saleId,
    bool _active
  )
    public
    nonStopped
    validCollection(_collection)
    storeOrCollectionAuthorized(_collection)
  {
    sales[_collection][_saleId].active = _active;
  }

  function setPrice(
    address _collection,
    uint256 _saleId,
    uint256 _newPrice
  )
    public
    nonStopped
    validCollection(_collection)
    storeOrCollectionAuthorized(_collection)
  {
    uint256 oldValue = sales[_collection][_saleId].price;
    sales[_collection][_saleId].price = _newPrice;
    emit PriceChanged(_collection, _saleId, oldValue, _newPrice);
  }

  function setSupply(
    address _collection,
    uint256 _saleId,
    uint256 _newSupply
  )
    public
    nonStopped
    validCollection(_collection)
    storeOrCollectionAuthorized(_collection)
  {
    uint256 currentSaleSupply = sales[_collection][_saleId].supply;
    uint256 currentTotalSupply = 0;
    for (uint256 i = 0; i < sales[_collection].length; i++) {
      currentTotalSupply += sales[_collection][i].supply;
    }
    require(
      currentTotalSupply - currentSaleSupply + _newSupply <=
        Collection(_collection).supply(),
      "SUPPLY: value exeeds collection max supply"
    );

    uint256 oldValue = sales[_collection][_saleId].supply;
    sales[_collection][_saleId].supply = uint216(_newSupply);
    emit SupplyChanged(_collection, _saleId, oldValue, _newSupply);
  }

  function setRoot(
    address _collection,
    uint256 _saleId,
    bytes32 _newRoot
  )
    public
    nonStopped
    validCollection(_collection)
    storeOrCollectionAuthorized(_collection)
  {
    bytes32 oldValue = sales[_collection][_saleId].whitelistRoot;
    sales[_collection][_saleId].whitelistRoot = _newRoot;
    emit WhitelistChanged(_collection, _saleId, oldValue, _newRoot);
  }

  function getState(address _collection, uint256 _saleId)
    external
    view
    validCollection(_collection)
    returns (Sale memory)
  {
    return sales[_collection][_saleId];
  }

  function getSalesCount(address _collection) external view returns (uint256) {
    return sales[_collection].length;
  }

  function validateCollection(address _collection) public view {
    require(
      factory.isCollection(_collection),
      "Collection is not part of the store"
    );
    require(
      !collection[_collection].isBlacklisted,
      "Collection has been blacklisted"
    );
  }

  function isAuthorized(address _user, address _collection)
    public
    view
    returns (bool)
  {
    return authorized[_user] || Collection(_collection).authorized(_user);
  }

  function transferOwnership(address newOwner)
    public
    virtual
    override(Authorizable, Ownable)
    onlyOwner
  {
    super.transferOwnership(newOwner);
  }

  function _addSale(address _collection, Sale memory _sale) internal {
    uint256 currentSupply = 0;
    for (uint256 i = 0; i < sales[_collection].length; i++) {
      currentSupply += sales[_collection][i].supply;
    }
    require(
      currentSupply + _sale.supply <= Collection(_collection).supply(),
      "SUPPLY: value exeeds collection max supply"
    );
    sales[_collection].push(_sale);
  }
}