// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

// =====================================================================
//
// |  \/  (_) |         | |                 |  _ \                   | |
// | \  / |_| | ___  ___| |_ ___  _ __   ___| |_) | __ _ ___  ___  __| |
// | |\/| | | |/ _ \/ __| __/ _ \| '_ \ / _ \  _ < / _` / __|/ _ \/ _` |
// | |  | | | |  __/\__ \ || (_) | | | |  __/ |_) | (_| \__ \  __/ (_| |
// |_|  |_|_|_|\___||___/\__\___/|_| |_|\___|____/ \__,_|___/\___|\__,_|
//
// =====================================================================
// ======================= ExpandedEntity ==============================
// =====================================================================

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./BaseEntity.sol";
import "../interfaces/IExpandedEntity.sol";

/**
 * @title ExpandedEntity
 * @author milestoneBased R&D Team
 *
 * @dev abstract contract which implemented the {IExpandedEntity} interface. A contract
 * that implements additional entity methods. Owner of the contract can be `UserEntity` contract only
 *
 * The contract inherits {BaseEntity}
 */
abstract contract ExpandedEntity is IExpandedEntity, BaseEntity {
  /**
   * @dev Initializes the contract setting the owner_ and contractsRegistry_.
   *
   * Requirements:
   *
   * - `owner_` must be `UserEntity` contract
   * - `contractsRegistry_` must not be equal to `ZERO_ADDRESS`
   *
   */
  // solhint-disable-next-line
  function __ExpandedEntity_init(address owner_, address contractsRegistry_)
    internal
    virtual
    onlyInitializing
  {
    __BaseEntity_init(owner_, contractsRegistry_);
    _entityTypeRequired(owner_);
  }

  /**
   * @dev Overrided {OwnerManager-_swapOwner} method for additional requiremment
   * that `newOwner_` is `UserEntity` contract
   *
   * See {OwnerManager-_swapOwner}
   */
  // solhint-disable-next-line ordering
  function _swapOwner(
    address prevOwner_,
    address oldOwner_,
    address newOwner_
  ) internal virtual override {
    _entityTypeRequired(newOwner_);
    super._swapOwner(prevOwner_, oldOwner_, newOwner_);
  }

  /**
   * @dev Overrided {OwnerManager-_isOwner} method which now provides next logic:
   * the owners of the `UserEntity` (which is owner of this contract) should
   * also be considered as the owners of this contract
   *
   * See {OwnerManager-_isOwner}
   */
  function _isOwner(address owner_)
    internal
    view
    virtual
    override
    returns (bool)
  {
    return
      owner_ == _getFirstOwner()
        ? true
        : OwnerManager(_getFirstOwner()).isOwner(owner_);
  }

  /**
   * @dev Throws if `entity_` is not registered as `UserEntity` contract in
   * entityFactory.
   */
  function _entityTypeRequired(address entity_) internal view virtual {
    if (
      _getEntityFactory().entityRegister(entity_) !=
      IEntityFactory.EntityType.UserEntity
    ) {
      revert IncorrectEntityType();
    }
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  // solhint-disable-next-line ordering
  uint256[50] private ___gap;
}