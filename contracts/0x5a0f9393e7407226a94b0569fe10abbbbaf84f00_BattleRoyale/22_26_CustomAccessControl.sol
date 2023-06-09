// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AddressArray.sol";

contract CustomAccessControl is AccessControl, Ownable {
  using AddressArray for AddressArray.Addresses;

  // Array of purchaser addresses
  AddressArray.Addresses users;
  bytes32 public constant SUPPORT_ROLE = keccak256("DEFAULT_SUPPORT_ROLE");

  function supportLevelAccess(address account) public view returns (bool) {
    return hasRole(SUPPORT_ROLE, account) || adminLevelAccess(account);
  }

  function adminLevelAccess(address account) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account) || account == owner();
  }

  function superAdminLevelAccess(address account) public view returns (bool) {
    return account == owner();
  }

  function grantSupportAccess(address payable account) public onlyOwner {
    if (users.exists(account)) {
      revokeAccessRole(account);
    } else {
      users.push(account);
    }
    grantRole(SUPPORT_ROLE, account);
  }

  function grantAdminAccess(address payable account) public onlyOwner {
    if (users.exists(account)) {
      revokeAccessRole(account);
    } else {
      users.push(account);
    }
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  function revokeAccessRole(address payable account) public payable onlyOwner returns (bool) {
    if (hasRole(DEFAULT_ADMIN_ROLE, account)) {
      revokeRole(DEFAULT_ADMIN_ROLE, account);
      users.remove(account);
      return true;
    } else if (hasRole(SUPPORT_ROLE, account)) {
      users.remove(account);
      revokeRole(SUPPORT_ROLE, account);
      return true;
    }
    return false;
  }

  function getAddressRole(address account) external returns (string memory) {
    if (hasRole(DEFAULT_ADMIN_ROLE, account)) {
      return 'ADMIN_ROLE';
    } else if (hasRole(SUPPORT_ROLE, account)) {
      return 'SUPPORT_ROLE';
    }
    return 'UNASSIGNED';
  }

  function getAllAccessAddresses() external view onlyOwner returns(address payable[] memory) {
    return users.getAll();
  }

  function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
    uint8 i = 0;
    while(i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlySupport() {
      require(supportLevelAccess(_msgSender()), "Caller does not have access");
      _;
  }

  modifier onlyAdmin() {
      require(adminLevelAccess(_msgSender()), "Caller does not have access");
      _;
  }
}