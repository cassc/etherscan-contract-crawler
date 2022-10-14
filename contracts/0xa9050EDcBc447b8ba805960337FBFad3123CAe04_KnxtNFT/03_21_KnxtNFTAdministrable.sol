// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

error UnAuthorized();

contract KnxtNFTAdministrable is AccessControlEnumerable {
  bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
  bytes32 public constant AIRDROPPER_ROLE = keccak256("AIRDROPPER_ROLE");

  constructor() {
    // roles can be granted and removed by any wallet who has administrator role
    _setRoleAdmin(ADMINISTRATOR_ROLE, ADMINISTRATOR_ROLE);
    _setRoleAdmin(AIRDROPPER_ROLE, ADMINISTRATOR_ROLE);
    // deployer is granted administrator role on contract deployment
    _grantRole(ADMINISTRATOR_ROLE, msg.sender);
  }

  // Security utils
  modifier onlyAirdropperOrAdministrator() {
    if (!hasRole(ADMINISTRATOR_ROLE, msg.sender) && !hasRole(AIRDROPPER_ROLE, msg.sender)) {
      revert UnAuthorized();
    }
    _;
  }
}