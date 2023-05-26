// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./FeeOwner.sol";
import "./Fee1155.sol";

/**
  @title A basic smart contract for tracking the ownership of SuperFarm Items.
  @author Tim Clancy

  This is the governing registry of all SuperFarm Item assets.
*/
contract FarmItemRecords is Ownable, ReentrancyGuard {

  /// A version number for this record contract's interface.
  uint256 public version = 1;

  /// A mapping for an array of all Fee1155s deployed by a particular address.
  mapping (address => address[]) public itemRecords;

  /// An event for tracking the creation of a new Item.
  event ItemCreated(address indexed itemAddress, address indexed creator);

  /// Specifically whitelist an OpenSea proxy registry address.
  address public proxyRegistryAddress;

  /**
    Construct a new item registry with a specific OpenSea proxy address.

    @param _proxyRegistryAddress An OpenSea proxy registry address.
  */
  constructor(address _proxyRegistryAddress) public {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  /**
    Create a Fee1155 on behalf of the owner calling this function. The Fee1155
    immediately mints a single-item collection.

    @param _uri The item group's metadata URI.
    @param _royaltyFee The creator's fee to apply to the created item.
    @param _initialSupply An array of per-item initial supplies which should be
                          minted immediately.
    @param _maximumSupply An array of per-item maximum supplies.
    @param _recipients An array of addresses which will receive the initial
                       supply minted for each corresponding item.
    @param _data Any associated data to use if items are minted this transaction.
  */
  function createItem(string calldata _uri, uint256 _royaltyFee, uint256[] calldata _initialSupply, uint256[] calldata _maximumSupply, address[] calldata _recipients, bytes calldata _data) external nonReentrant returns (Fee1155) {
    FeeOwner royaltyFeeOwner = new FeeOwner(_royaltyFee, 30000);
    Fee1155 newItemGroup = new Fee1155(_uri, royaltyFeeOwner, proxyRegistryAddress);
    newItemGroup.create(_initialSupply, _maximumSupply, _recipients, _data);

    // Transfer ownership of the new Item to the user then store a reference.
    royaltyFeeOwner.transferOwnership(msg.sender);
    newItemGroup.transferOwnership(msg.sender);
    address itemAddress = address(newItemGroup);
    itemRecords[msg.sender].push(itemAddress);
    emit ItemCreated(itemAddress, msg.sender);
    return newItemGroup;
  }

  /**
    Allow a user to add an existing Item contract to the registry.

    @param _itemAddress The address of the Item contract to add for this user.
  */
  function addItem(address _itemAddress) external {
    itemRecords[msg.sender].push(_itemAddress);
  }

  /**
    Get the number of entries in the Item records mapping for the given user.

    @return The number of Items added for a given address.
  */
  function getItemCount(address _user) external view returns (uint256) {
    return itemRecords[_user].length;
  }
}