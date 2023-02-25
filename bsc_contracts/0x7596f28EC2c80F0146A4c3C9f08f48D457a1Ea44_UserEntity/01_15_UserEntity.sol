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
// ======================= UserEntity =================================
// =====================================================================

import "./abstract/BaseEntity.sol";
import "./interfaces/IUserEntity.sol";

/**
 * @title UserEntity
 * @author milestoneBased R&D Team
 *
 * @dev main of the `BaseEntity` implementations for extracting an entity
 * for other parts of infrastructure
 */
contract UserEntity is IUserEntity, BaseEntity {
  /**
   * @dev Initializes the contract's settings the owner_ and contractsRegistry_.
   *
   * Requirements:
   *
   * - `contractsRegistry_` must not be equal to `ZERO_ADDRESS`
   * - can be called only once
   */
  function initialize(address owner_, address contractsRegistry_)
    external
    virtual
    override
    initializer
  {
    __BaseEntity_init(owner_, contractsRegistry_);
  }

  /**
   * @dev Overrided {OwnerManager-_swapOwner} method for additional logic
   * of notifing and changing the owner on the `EntityFactory` side
   *
   * See {OwnerManager-_swapOwner}
   */
  function _swapOwner(
    address prevOwner_,
    address oldOwner_,
    address newOwner_
  ) internal virtual override {
    super._swapOwner(prevOwner_, oldOwner_, newOwner_);
    IEntityFactory factory = _getEntityFactory();
    factory.removeOwnerFromUserEntity(oldOwner_);
    factory.addOwnerToUserEntity(newOwner_);
  }
}