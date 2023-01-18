// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
pragma solidity ^0.8.4;

contract Admin is Ownable {
  // Listing all admins
  address[] public admins;

  // Modifier for easier checking if user is admin
  mapping(address => bool) public isAdmin;

  // Modifier restricting access to only admin
  modifier onlyAdmin() {
    require(isAdmin[msg.sender], "ONLY_ADMIN");
    _;
  }

  // Constructor to set initial admins during deployment
  constructor(address[] memory _admins) {
    for (uint256 i = 0; i < _admins.length; i++) {
      admins.push(_admins[i]);
      isAdmin[_admins[i]] = true;
    }
  }

  function addAdmin(address _adminAddress) external onlyOwner {
    // Can't add 0x address as an admin
    require(_adminAddress != address(0x0), "ADDRESS_ZERO");
    // Can't add existing admin
    require(!isAdmin[_adminAddress], "ALREADY_ADMIN");
    // Add admin to array of admins
    admins.push(_adminAddress);
    // Set mapping
    isAdmin[_adminAddress] = true;
  }

  function removeAdmin(address _adminAddress) external onlyOwner {
    // Admin has to exist
    require(isAdmin[_adminAddress], "NOT_ADMIN");
    require(admins.length > 1, "NO_ADMIN_LEFT");
    uint256 i = 0;

    while (admins[i] != _adminAddress) {
      if (i == admins.length) {
        revert("NOT_EXIST");
      }
      i++;
    }

    // Copy the last admin position to the current index
    admins[i] = admins[admins.length - 1];

    isAdmin[_adminAddress] = false;

    // Remove the last admin, since it's double present
    admins.pop();
  }

  // Fetch all admins
  function getAllAdmins() external view returns (address[] memory) {
    return admins;
  }
}