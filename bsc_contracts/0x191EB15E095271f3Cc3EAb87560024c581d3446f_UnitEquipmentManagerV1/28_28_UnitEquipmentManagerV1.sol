// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
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
  address belongsTo;
}

/**
 * @notice Struct representing the result of a pagination operation.
 */
struct Pagination {
  address[] items;
  uint256 size;
}

/**
 * @dev Contract for managing equipment.
 */
contract UnitEquipmentManagerV1 is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
  address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  address public SAMURAI_ADDRESS;

  /**
   * @notice Role for the contract creator.
   */
  bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

  IMarketplace public marketplace;

  address[] private items;

  mapping(address => address) public belongsTo;

  /**
   * @notice Initializes the upgradable contract.
   */
  function initialize(IMarketplace _marketplace, address _SAMURAI_ADDRESS) public virtual initializer {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(CREATOR_ROLE, msg.sender);

    marketplace = _marketplace;
    SAMURAI_ADDRESS = _SAMURAI_ADDRESS;

    items = new address[](0);
  }

  /**
   * @notice Creates a new equipment.
   * @param equipmentDetail Details of the equipment to be created.
   */
  function _createEquipement(EquipmentDetail calldata equipmentDetail) private {
    Equipment equipment = new Equipment(equipmentDetail.name, equipmentDetail.name, equipmentDetail.tokenURI);

    // enable marketplace trade
    {
      address[] memory tokenAddresses = new address[](1);
      tokenAddresses[0] = address(equipment);

      bool[] memory values = new bool[](1);
      values[0] = true;

      marketplace.enableTrade(tokenAddresses, values);
    }

    items.push(address(equipment));

    belongsTo[address(equipment)] = equipmentDetail.belongsTo;

    emit EquipmentCreated(address(equipment), equipmentDetail.belongsTo, equipmentDetail);
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
   * @notice Equip an nft with an equipment.
   * @param _equipmentAddress Equipment address to be used.
   * @param _equipmentId Equipment tokenId to be used.
   * @param _nftId Nft to be equiped.
   */
  function _equip(address _equipmentAddress, uint _equipmentId, uint _nftId) private {
    address _nftAddress = belongsTo[_equipmentAddress];
    require(_nftAddress != address(0), "UnitEquipmentManager::_equip: equipment isn't available");

    require(Equipment(_nftAddress).ownerOf(_nftId) == msg.sender, "UnitEquipmentManager::_equip: sender isn't the nft owner");
    require(Equipment(_equipmentAddress).ownerOf(_equipmentId) == msg.sender, "UnitEquipmentManager::_equip: sender isn't the equipment owner");

    if (_nftAddress == SAMURAI_ADDRESS) {
      require(_nftId > 4999, "UnitEquipmentManager::_equip: samurai id has to be greater than 4999");
    }

    Equipment(_equipmentAddress).transferFrom(msg.sender, BURN_ADDRESS, _equipmentId);

    emit Equipped(msg.sender, _equipmentAddress, _nftAddress, _equipmentId, _nftId);
  }

  /**
   * @notice Equip an array of nfts with an array of equipment.
   * @param _equipmentAddresses Array of equipment addresses to be used.
   * @param _equipmentIds Array of equipment tokenIds to be used.
   * @param _nftIds Array of nfts to be equiped.
   */
  function equip(address[] calldata _equipmentAddresses, uint[] calldata _equipmentIds, uint[] calldata _nftIds) external {
    require(_equipmentAddresses.length == _equipmentIds.length, "UnitEquipmentManager::equip: equipmentAddresses and equipmentIds have different lengths");
    require(_equipmentIds.length == _nftIds.length, "UnitEquipmentManager::equip: equipmentIds and nftIds have different lengths");

    for (uint256 i = 0; i < _equipmentAddresses.length; i++) {
      _equip(_equipmentAddresses[i], _equipmentIds[i], _nftIds[i]);
    }
  }

  event EquipmentCreated(address indexed equipmentAddress, address indexed nftAddress, EquipmentDetail equipment);
  event Equipped(address indexed owner, address indexed equipmentAddress, address indexed nftAddress, uint equipmentId, uint nftId);
}