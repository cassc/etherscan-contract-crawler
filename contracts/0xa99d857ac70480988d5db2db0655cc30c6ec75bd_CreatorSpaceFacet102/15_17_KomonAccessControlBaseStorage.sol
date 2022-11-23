// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library KomonAccessControlBaseStorage {
  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
  bytes32 public constant KOMON_WEB_ROLE = keccak256("KOMON_WEB_ROLE");
  bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

  struct Layout {
    mapping(bytes32 => RoleData) _roles;
    mapping(uint256 => address) creatorTokens;
    address _komonExchangeAccount;
    address _assetsToKomonAccount;
  }

  struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("komon.contracts.access.storage.KomonAccessControlBase");

  function layout() internal pure returns (Layout storage lay) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      lay.slot := slot
    }
  }

  function hasKomonWebRole(address account) internal view returns (bool) {
    return hasRole(KOMON_WEB_ROLE, account);
  }

  function hasRole(bytes32 role, address account) internal view returns (bool) {
    return KomonAccessControlBaseStorage.layout()._roles[role].members[account];
  }

  function hasAdminRole(address account) internal view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }
}
