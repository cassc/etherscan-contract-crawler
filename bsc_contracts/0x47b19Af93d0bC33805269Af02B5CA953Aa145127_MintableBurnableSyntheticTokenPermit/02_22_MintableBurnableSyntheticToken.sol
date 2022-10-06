// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;
import {MintableBurnableERC20} from './MintableBurnableERC20.sol';

/**
 * @title Synthetic token contract
 * Inherits from MintableBurnableERC20
 */
contract MintableBurnableSyntheticToken is MintableBurnableERC20 {
  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals
  ) MintableBurnableERC20(tokenName, tokenSymbol, tokenDecimals) {}

  /**
   * @notice Add minter role to account
   * @dev The caller must have the admin role
   * @param account The address on which minter role is added
   */
  function addMinter(address account) public override {
    super.addMinter(account);
  }

  /**
   * @notice Add burner role to account
   * @dev The caller must have the admin role
   * @param account The address to which burner role is added
   */
  function addBurner(address account) public override {
    super.addBurner(account);
  }

  /**
   * @notice Add admin role to account.
   * @dev The caller must have the admin role.
   * @param account The address to which the admin role is added.
   */
  function addAdmin(address account) public override {
    super.addAdmin(account);
  }

  /**
   * @notice Add admin, minter and burner roles to account.
   * @dev The caller must have the admin role.
   * @param account The address to which the admin, minter and burner roles are added.
   */
  function addAdminAndMinterAndBurner(address account) public override {
    super.addAdminAndMinterAndBurner(account);
  }

  /**
   * @notice Minter renounce to minter role
   */
  function renounceMinter() public override {
    super.renounceMinter();
  }

  /**
   * @notice Burner renounce to burner role
   */
  function renounceBurner() public override {
    super.renounceBurner();
  }

  /**
   * @notice Admin renounce to admin role
   */
  function renounceAdmin() public override {
    super.renounceAdmin();
  }

  /**
   * @notice Admin, minter and murner renounce to admin, minter and burner roles
   */
  function renounceAdminAndMinterAndBurner() public override {
    super.renounceAdminAndMinterAndBurner();
  }

  /**
   * @notice Checks if a given account holds the minter role.
   * @param account The address which is checked for the minter role.
   * @return bool True if the provided account is a minter.
   */
  function isMinter(address account) public view returns (bool) {
    return hasRole(MINTER_ROLE, account);
  }

  /**
   * @notice Checks if a given account holds the burner role.
   * @param account The address which is checked for the burner role.
   * @return bool True if the provided account is a burner.
   */
  function isBurner(address account) public view returns (bool) {
    return hasRole(BURNER_ROLE, account);
  }

  /**
   * @notice Checks if a given account holds the admin role.
   * @param account The address which is checked for the admin role.
   * @return bool True if the provided account is an admin.
   */
  function isAdmin(address account) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  /**
   * @notice Accessor method for the list of member with admin role
   * @return array of address with admin role
   */
  function getAdminMembers() external view returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(DEFAULT_ADMIN_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  /**
   * @notice Accessor method for the list of member with minter role
   * @return array of address with minter role
   */
  function getMinterMembers() external view returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(MINTER_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(MINTER_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  /**
   * @notice Accessor method for the list of member with burner role
   * @return array of address with burner role
   */
  function getBurnerMembers() external view returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(BURNER_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(BURNER_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }
}