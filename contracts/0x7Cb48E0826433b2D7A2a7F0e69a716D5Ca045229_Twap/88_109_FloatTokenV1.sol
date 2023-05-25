// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "./ERC20PermitUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./ERC20SupplyControlledUpgradeable.sol";

/**
 * @dev {ERC20} FLOAT token, including:
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
contract FloatTokenV1 is
  ERC20PausableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20SupplyControlledUpgradeable
{
  /**
   * @notice Construct a FloatTokenV1 instance
   * @param governance The default role controller, minter and pauser for the contract.
   * @param minter An additional minter (useful for quick launches, check this is revoked)
   * @dev We expect minters to be defined on deploy, e.g. AuctionHouse should get minter role
   */
  function initialize(address governance, address minter) external initializer {
    __Context_init_unchained();
    __ERC20_init_unchained("Float Protocol: FLOAT", "FLOAT");
    __ERC20Permit_init_unchained("Float Protocol: FLOAT", "1");
    __ERC20Pausable_init_unchained(governance);
    __ERC20SupplyControlled_init_unchained(governance);

    _setupRole(DEFAULT_ADMIN_ROLE, governance);

    // Quick launches
    _setupRole(MINTER_ROLE, minter);
  }

  /// @dev Hint to compiler, that this override has already occured.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}