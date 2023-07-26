// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./INZDD.sol";

/**
 * @title NZDD.sol
 * @notice An ERC-20 token for the New Zealand Digital Dollar project.
 */
contract NZDD is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  ERC20PermitUpgradeable,
  UUPSUpgradeable,
  INZDD
{
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          ROLES                             */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  /**
   * @notice The role assigned to Master Admin, the admin that can upgrade this contract
   */
  bytes32 public constant MASTER_ADMIN_ROLE = keccak256("MASTER_ADMIN_ROLE");

  /**
   * @notice The role assigned to accounts that can mint ERC20 tokens.
   */
  bytes32 public constant NZDD_MINTER_ROLE = keccak256("NZDD_MINTER_ROLE");

  /**
   * @notice The role assigned to accounts that blacklist addresses (block from transferring).
   */
  bytes32 public constant NZDD_BLACKLISTER_ROLE =
    keccak256("NZDD_BLACKLISTER_ROLE");

  /**
   * @dev The mapping that tracks the blacklisted addresses (set by NZDD_BLACKLISTER_ROLE)
   */
  mapping(address => bool) internal blacklisted;

  /**
   * @notice Intialize function - part of the UUPS upgradeable standard that allows for initial set up
   * of an upgradeable contract.
   * @param _masterAdmin The account that will be assigned the MASTER_ADMIN_ROLE.
   * @param _defaultAdmin The account that will be assigned the DEFAULT_ADMIN_ROLE.
   * @param _minter The account that will be assigned the NZDD_MINTER_ROLE.
   * @param _blacklister The account that will be assigned the NZDD_BLACKLISTER_ROLE.
   */
  function initialize(
    address _masterAdmin,
    address _defaultAdmin,
    address _minter,
    address _blacklister
  ) public initializer {
    __ERC20_init("New Zealand Digital Dollar", "NZDD");
    __ERC20Burnable_init();
    __Pausable_init();
    __AccessControl_init();
    __ERC20Permit_init("New Zealand Digital Dollar");
    __UUPSUpgradeable_init();

    // ensure constructor args are not empty
    if (_masterAdmin == address(0)) revert EmptyParameter("_masterAdmin");
    if (_defaultAdmin == address(0)) revert EmptyParameter("_defaultAdmin");
    if (_minter == address(0)) revert EmptyParameter("_minter");
    if (_blacklister == address(0)) revert EmptyParameter("_blacklister");

    // the master admin manages itself - the default admin cannot assign MASTER_ADMIN_ROLE
    _setRoleAdmin(MASTER_ADMIN_ROLE, MASTER_ADMIN_ROLE);

    // the master admin manages the default admin role
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, MASTER_ADMIN_ROLE);

    // assign roles to provided addresses
    _grantRole(MASTER_ADMIN_ROLE, _masterAdmin);
    _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    _grantRole(NZDD_MINTER_ROLE, _minter);
    _grantRole(NZDD_BLACKLISTER_ROLE, _blacklister);
  }

  function pause() public override onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() public override onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function mint(
    address _to,
    uint256 _amount
  ) public override onlyRole(NZDD_MINTER_ROLE) {
    if (_to == address(0)) revert EmptyParameter("_to");
    if (_amount == 0) revert EmptyParameter("_amount");

    _mint(_to, _amount);
  }

  function isBlacklisted(
    address _account
  ) external view override returns (bool) {
    return blacklisted[_account];
  }

  function blacklist(
    address _account
  ) external override onlyRole(NZDD_BLACKLISTER_ROLE) {
    if (blacklisted[_account]) {
      revert AddressAlreadyBlacklisted(_account);
    }

    blacklisted[_account] = true;
    emit Blacklisted(_account);
  }

  function unBlacklist(
    address _account
  ) external override onlyRole(NZDD_BLACKLISTER_ROLE) {
    if (!blacklisted[_account]) {
      revert AddressNotBlacklisted(_account);
    }

    blacklisted[_account] = false;
    emit UnBlacklisted(_account);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                IMPLEMENTATION OVERRIDES                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /**
   * @notice Overriding the default amount of decimals (18) to be 6.
   */
  function decimals() public pure override returns (uint8) {
    return 6;
  }

  /**
   * @notice The burn function is overridden to ensure that only the NZDD_MINTER_ROLE can burn tokens.
   * @param _amount The amount of tokens to be burnt.
   * @inheritdoc ERC20BurnableUpgradeable
   */
  function burn(uint256 _amount) public override onlyRole(NZDD_MINTER_ROLE) {
    super.burn(_amount);
  }

  /**
   * @notice Internal hook function called when transferring tokens
   *         Overriden to check and revert if:
   *           - Contract is in paused state
   *           - If from or to address is a blacklisted address
   * @inheritdoc ERC20Upgradeable
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    if (blacklisted[from]) {
      revert AddressBlacklisted(from);
    }
    if (blacklisted[to]) {
      revert AddressBlacklisted(to);
    }

    super._beforeTokenTransfer(from, to, amount);
  }

  /**
   * @notice Internal function called when upgrading a UUPS contract.
   *         Allows for upgradeability of this contract through UUPS standard.
   * @param newImplementation The new implementation contract to point this contract to.
   * @dev This function is only callable by accounts with the MASTER_ADMIN_ROLE.
   */
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyRole(MASTER_ADMIN_ROLE) {}
}