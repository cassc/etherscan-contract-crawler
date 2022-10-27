// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


/// @notice providing an ownership access control mechanism
contract HasOwners {

  event OwnerAdded(address indexed owner);
  event OwnerRemoved(address indexed owner);

  /// cannot use the zero address
  error InvalidAddress();

  address[] public owners;
  mapping(address => bool) public isOwner;

  constructor(address[] memory owners_) {
    require(owners_.length > 0, "there must be at least one owner");
    for (uint i = 0; i < owners_.length; i++) addOwner_(owners_[i]);
  }

  modifier onlyOwner { require(isOwner[msg.sender], "invalid sender; must be owner"); _; }

  modifier valid(address account) { if (account == address(0)) revert InvalidAddress(); _; }

  function getOwners() public view returns (address[] memory) { return owners; }

  function addOwner(address owner) external onlyOwner { addOwner_(owner); }

  function addOwner_(address owner) private valid(owner) {
    if (!isOwner[owner]) {
      isOwner[owner] = true;
      owners.push(owner);
      emit OwnerAdded(owner);
    }
  }

  /// @notice revoke an `account` owner access (while ensuring at least one owner remains)
  function removeOwner(address owner) external onlyOwner {
    require(isOwner[owner], 'only owners can be removed');
    require(owners.length > 1, 'can not remove last owner');
    isOwner[owner] = false;
    for (uint i = 0; i < owners.length; i++) {
      if (owners[i] == owner) {
        owners[i] = owners[owners.length - 1];
        owners.pop();
        emit OwnerRemoved(owner);
        break;
      }
    }
  }

}