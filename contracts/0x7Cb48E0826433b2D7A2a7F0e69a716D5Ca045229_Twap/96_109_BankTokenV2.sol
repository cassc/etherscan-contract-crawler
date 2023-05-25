// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "../lib/Upgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./ERC20SupplyControlledUpgradeable.sol";

/**
 * @dev {ERC20} BANK token, including:
 *
 * - a minter role that allows for token minting (necessary for stabilisation)
 * - the ability to burn tokens (necessary for stabilisation)
 * - the use of permits to reduce gas costs
 * - a pauser role that allows to stop all token transfers
 *
 * This contract uses OpenZeppelin {AccessControlUpgradeable} to lock permissioned functions
 * using the different roles.
 * This contract is upgradable.
 */
contract BankTokenV2 is
  ERC20PausableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20SupplyControlledUpgradeable,
  Upgradeable
{
  /**
   * @notice Construct a brand new BankTokenV2 instance
   * @param governance The default role controller, minter and pauser for the contract.
   * @dev We expect minters to be defined after deploy, e.g. AuctionHouse should get minter role
   */
  function initialize(address governance) external initializer {
    _version = 2;

    __Context_init_unchained();
    __ERC20_init_unchained("Float Bank", "BANK");
    __ERC20Permit_init_unchained("Float Protocol: BANK", "2");
    __ERC20Pausable_init_unchained(governance);
    __ERC20SupplyControlled_init_unchained(governance);
    _setupRole(DEFAULT_ADMIN_ROLE, governance);
  }

  /**
   * @notice Upgrade from V1, and initialise the relevant "new" state
   * @dev Uses upgradeAndCall in the ProxyAdmin, to call upgradeToAndCall, which will delegatecall this function.
   * _version keeps this single use
   * onlyProxyAdmin ensures this only occurs on upgrade
   */
  function upgrade() external onlyProxyAdmin {
    require(_version < 2, "BankTokenV2/AlreadyUpgraded");
    _version = 2;
    _domainSeparator = EIP712.domainSeparatorV4("Float Protocol: BANK", "2");
  }

  /// @dev Hint to compiler that this override has already occured.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}