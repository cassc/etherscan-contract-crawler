// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./RecoverableUpgradeable.sol";
import "./Equipment.sol";

interface IMarketplace {
  /**
   * @notice Enables trade for the specified nft tokens.
   * @param nfts Token addresses to enable trade for.
   * @param values Boolean values indicating whether to enable or disable trade for the nft tokens.
   */
  function enableTrade(address[] calldata nfts, bool[] calldata values) external;
}

/**
 * @notice Struct representing the details of an equipment.
 */
struct EquipmentDetail {
  string name;
  string tokenURI;
}

/**
 * @notice Struct representing a store item.
 */
struct StoreItem {
  address tokenAddress;
  StoreType storeType;
  uint64 rarity;
  uint64 sold;
  uint64 maxSupply;
  int64 cappedSupply;
}

/**
 * @notice Struct representing the result of a pagination operation.
 */
struct Pagination {
  address[] items;
  uint256 size;
}

/**
 * @notice Enum representing the type of store.
 */
enum StoreType {
  Merchant,
  Blackmarket
}

/**
 * @notice Enum representing the type of price.
 */
enum PriceType {
  BNB,
  ERC20
}

/**
 * @dev Contract for managing equipment.
 */
contract EquipmentManagerV1 is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, RecoverableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**
   * @notice Role for the contract creator.
   */
  bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

  /**
   * @notice Role for the merchant.
   */
  bytes32 public constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");

  IMarketplace public marketplace;

  address[] private items;
  address[] private merchantStore;
  address[] private blackmarketStore;

  /**
   * @notice Mapping from token address to store item.
   */
  mapping(address => StoreItem) public store;

  /**
   * @notice Mapping from price type to price.
   */
  mapping(PriceType => uint256[]) public rarityPrices;

  /**
   * @notice ERC20 token used for buying equipment.
   */
  IERC20Upgradeable public erc20Token;

  /**
   * @notice Initializes the upgradable contract.
   */
  function initialize(IMarketplace _marketplace, IERC20Upgradeable _erc20Token, uint256[] calldata _bnbRarityPrices, uint256[] calldata _erc20RarityPrices) public virtual initializer {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(CREATOR_ROLE, msg.sender);
    _grantRole(MERCHANT_ROLE, msg.sender);

    marketplace = _marketplace;

    erc20Token = _erc20Token;

    rarityPrices[PriceType.BNB] = _bnbRarityPrices;
    rarityPrices[PriceType.ERC20] = _erc20RarityPrices;

    items = new address[](0);
    merchantStore = new address[](0);
    blackmarketStore = new address[](0);
  }

  /**
   * @notice Creates a new equipment.
   * @param equipmentDetail Details of the equipment to be created.
   */
  function _createEquipement(EquipmentDetail calldata equipmentDetail) private {
    Equipment equipment = new Equipment(equipmentDetail.name, equipmentDetail.name, equipmentDetail.tokenURI);

    address[] memory tokenAddresses = new address[](1);
    tokenAddresses[0] = address(equipment);

    bool[] memory values = new bool[](1);
    values[0] = true;

    items.push(tokenAddresses[0]);

    marketplace.enableTrade(tokenAddresses, values);

    emit EquipmentCreated(tokenAddresses[0], equipmentDetail);
  }

  /**
   * @notice Creates new equipment from array.
   * @param equipmentDetails Array of details of the equipment to be created.
   */
  function createEquipement(EquipmentDetail[] calldata equipmentDetails) external onlyRole(CREATOR_ROLE) {
    for (uint256 i = 0; i < equipmentDetails.length; i++) {
      _createEquipement(equipmentDetails[i]);
    }
  }

  /**
   * @dev Private helper function for pagination.
   * @param _skip Number of items to skip.
   * @param _limit Maximum number of items to return.
   * @param _arr Array to paginate.
   * @return Pagination result.
   */
  function paginate(uint256 _skip, int256 _limit, address[] memory _arr) private pure returns (Pagination memory) {
    uint limit = (_limit == -1 || uint(_limit) > _arr.length - _skip) ? _arr.length - _skip : uint(_limit);

    address[] memory _items = new address[](limit);
    for (uint256 i = _skip; i < _skip + limit; i++) {
      _items[i - _skip] = _arr[i];
    }

    return Pagination({ items: _items, size: _arr.length });
  }

  /**
   * @notice Returns a paginated list of all equipment.
   * @param _skip Number of items to skip.
   * @param _limit Maximum number of items to return.
   * @return Paginated list of all equipment.
   */
  function getItems(uint256 _skip, int256 _limit) external view returns (Pagination memory) {
    return paginate(_skip, _limit, items);
  }

  /**
   * @notice Returns a paginated list of items in the merchant store.
   * @param _skip Number of items to skip.
   * @param _limit Maximum number of items to return.
   * @return Paginated list of items in the merchant store.
   */
  function getMerchantStore(uint256 _skip, int256 _limit) external view returns (Pagination memory) {
    return paginate(_skip, _limit, merchantStore);
  }

  /**
   * @notice Returns a paginated list of items in the blackmarket store.
   * @param _skip Number of items to skip.
   * @param _limit Maximum number of items to return.
   * @return Paginated list of items in the blackmarket store.
   */
  function getBlackmarketStore(uint256 _skip, int256 _limit) external view returns (Pagination memory) {
    return paginate(_skip, _limit, blackmarketStore);
  }

  /**
   * @notice Returns rarity prices per price type.
   * @param _priceType Price type.
   * @return Array of rarity prices per type.
   */
  function getRarityPrices(PriceType _priceType) external view returns (uint256[] memory) {
    return rarityPrices[_priceType];
  }

  /**
   * @notice Returns bnb & erc20 total prices for an array of equipment.
   * @param _tokenAddresses Array of equipment addresses.
   * @return bnb & erc20 total prices for an array of equipment.
   */
  function getTotalPrices(address[] calldata _tokenAddresses) public view returns (uint256, uint256) {
    uint256 bnb = 0;
    uint256 erc20 = 0;

    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      address tokenAddress = _tokenAddresses[i];
      StoreItem storage storeItem = store[tokenAddress];

      // Ensure the equipment exists in the store
      require(storeItem.tokenAddress != address(0), "EquipmentManager::getTotalPrices: equipment not found");

      if (storeItem.storeType == StoreType.Merchant) {
        erc20 += rarityPrices[PriceType.ERC20][storeItem.rarity - 1];
      } else {
        bnb += rarityPrices[PriceType.BNB][storeItem.rarity - 1];
      }
    }

    return (bnb, erc20);
  }

  /**
   * @notice Sets the items in the merchant store.
   * @param _storeItems Array of store items to set for the merchant store.
   */
  function setMerchantStore(StoreItem[] calldata _storeItems) external onlyRole(MERCHANT_ROLE) {
    // reset store for old merchant store items
    for (uint256 i = 0; i < merchantStore.length; i++) {
      store[merchantStore[i]].tokenAddress = address(0);
    }

    // empty the merchant store array
    delete merchantStore;

    // populate the new store items and the new merchant array
    for (uint256 i = 0; i < _storeItems.length; i++) {
      require(_storeItems[i].tokenAddress != address(0), "EquipmentManager::setMerchantStore: invalid address");
      require(_storeItems[i].maxSupply != 0, "EquipmentManager::setMerchantStore: invalid maxSupply value");
      require(_storeItems[i].cappedSupply == -1 || int64(_storeItems[i].maxSupply) <= _storeItems[i].cappedSupply, "EquipmentManager::setMerchantStore:invalid cappedSupply value");

      store[_storeItems[i].tokenAddress] = _storeItems[i];
      merchantStore.push(_storeItems[i].tokenAddress);
    }

    emit MerchantStoreUpdated(_storeItems);
  }

  /**
   * @notice Sets the items in the blackmarket store.
   * @param _storeItems Array of store items to set for the blackmarket store.
   */
  function setBlackmarketStore(StoreItem[] calldata _storeItems) external onlyRole(MERCHANT_ROLE) {
    // reset store for old blackmarket store items
    for (uint256 i = 0; i < blackmarketStore.length; i++) {
      store[blackmarketStore[i]].tokenAddress = address(0);
    }

    // empty the blackmarket store array
    delete blackmarketStore;

    // populate the new store items and the new blackmarket array
    for (uint256 i = 0; i < _storeItems.length; i++) {
      require(_storeItems[i].tokenAddress != address(0), "EquipmentManager::setBlackmarketStore: invalid address");
      require(_storeItems[i].maxSupply != 0, "EquipmentManager::setBlackmarketStore: invalid maxSupply value");
      require(_storeItems[i].cappedSupply == -1 || int64(_storeItems[i].maxSupply) <= _storeItems[i].cappedSupply, "EquipmentManager::setBlackmarketStore:invalid cappedSupply value");

      store[_storeItems[i].tokenAddress] = _storeItems[i];
      blackmarketStore.push(_storeItems[i].tokenAddress);
    }

    emit BlackmarketStoreUpdated(_storeItems);
  }

  /**
   * @dev Private helper function for buying an equipment.
   * @param tokenAddress Address of the equipment to be bought.
   */
  function _buy(address tokenAddress) private {
    StoreItem storage storeItem = store[tokenAddress];

    // Ensure the equipment is in stock
    require(storeItem.sold < storeItem.maxSupply, "EquipmentManager::buy: equipment is out of stock");

    // Determine the price of the equipment
    PriceType priceType = storeItem.storeType == StoreType.Merchant ? PriceType.ERC20 : PriceType.BNB;
    uint256 price = rarityPrices[priceType][storeItem.rarity - 1];

    // Increase the number of sold equipment
    storeItem.sold += 1;

    // Mint the equipment to the buyer
    Equipment(tokenAddress).mint(msg.sender);

    if (priceType == PriceType.ERC20) {
      erc20Token.safeTransferFrom(msg.sender, address(this), price);
    }

    emit EquipmentBought(msg.sender, storeItem.tokenAddress, storeItem, price);
  }

  /**
   * @notice Buys an array of equipment.
   * @param tokenAddresses Array of addresses of the equipment to be bought.
   */
  function buy(address[] calldata tokenAddresses) external payable nonReentrant {
    (uint256 bnb, ) = getTotalPrices(tokenAddresses);
    require(msg.value == bnb, "EquipmentManager::buy: invalid bnb amount");

    for (uint256 i = 0; i < tokenAddresses.length; i++) {
      _buy(tokenAddresses[i]);
    }
  }

  /**
   * @notice Updates the price per rarity of the equipment.
   * @param _priceType Type of price (BNB or ERC20).
   * @param _prices New rarity prices.
   */
  function setRarityPrices(PriceType _priceType, uint256[] calldata _prices) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_prices.length == 5, "EquipmentManager::setRarityPrices: invalid prices length");

    rarityPrices[_priceType] = _prices;

    emit RarityPricesUpdated(_priceType, _prices);
  }

  /**
   * @notice Updates ERC20 token address.
   * @param _erc20Token New ERC20 address.
   */
  function setERC20Erc20Token(IERC20Upgradeable _erc20Token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    erc20Token = _erc20Token;

    emit ERC20TokenUpdated(address(_erc20Token));
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  event EquipmentCreated(address indexed equipmentAddress, EquipmentDetail equipment);
  event MerchantStoreUpdated(StoreItem[] storeItems);
  event BlackmarketStoreUpdated(StoreItem[] storeItems);
  event EquipmentBought(address indexed buyer, address indexed equipmentAddress, StoreItem storeItem, uint256 price);
  event RarityPricesUpdated(PriceType priceType, uint256[] prices);
  event ERC20TokenUpdated(address indexed erc20Token);
}