// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./FeeOwner.sol";
import "./Shop1155.sol";

/**
  @title A basic smart contract for tracking the ownership of SuperFarm Shops.
  @author Tim Clancy

  This is the governing registry of all SuperFarm Shop assets.
*/
contract FarmShopRecords is Ownable, ReentrancyGuard {

  /// A version number for this record contract's interface.
  uint256 public version = 1;

  /// The current platform fee owner to force when creating Shops.
  FeeOwner public platformFeeOwner;

  /// A mapping for an array of all Shop1155s deployed by a particular address.
  mapping (address => address[]) public shopRecords;

  /// An event for tracking the creation of a new Shop.
  event ShopCreated(address indexed shopAddress, address indexed creator);

  /**
    Construct a new registry of SuperFarm records with a specified platform fee owner.

    @param _feeOwner The address of the FeeOwner due a portion of all Shop earnings.
  */
  constructor(FeeOwner _feeOwner) public {
    platformFeeOwner = _feeOwner;
  }

  /**
    Allows the registry owner to update the platform FeeOwner to use upon Shop creation.

    @param _feeOwner The address of the FeeOwner to make the new platform fee owner.
  */
  function changePlatformFeeOwner(FeeOwner _feeOwner) external onlyOwner {
    platformFeeOwner = _feeOwner;
  }

  /**
    Create a Shop1155 on behalf of the owner calling this function. The Shop
    supports immediately registering attached Stakers if provided.

    @param _name The name of the Shop to create.
    @param _stakers An array of Stakers to attach to the new Shop.
  */
  function createShop(string calldata _name, Staker[] calldata _stakers) external nonReentrant returns (Shop1155) {
    Shop1155 newShop = new Shop1155(_name, platformFeeOwner, _stakers);

    // Transfer ownership of the new Shop to the user then store a reference.
    newShop.transferOwnership(msg.sender);
    address shopAddress = address(newShop);
    shopRecords[msg.sender].push(shopAddress);
    emit ShopCreated(shopAddress, msg.sender);
    return newShop;
  }

  /**
    Get the number of entries in the Shop records mapping for the given user.

    @return The number of Shops added for a given address.
  */
  function getShopCount(address _user) external view returns (uint256) {
    return shopRecords[_user].length;
  }
}