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
// ======================= IEntityFactory ==============================
// =====================================================================

/**
 * @title IEntityFactory
 * @author milestoneBased R&D Team
 *
 * @dev  External interface of `EntityFactory`
 */
interface IEntityFactory {
  /**
   * @dev Throws if a certain field equal ZERO_ADDRESS, which shouldn't be
   */
  error ZeroAddress();

  /**
   * @dev Throws if the user wanted to create the second `UserEntity` when he has active `UserEntty`
   */
  error EntityAlreadyExistsForUser();

  /**
   * @dev Throws if user entity not exists by user wanted create `CompanyEntity`
   * or `ProjectEntity`
   */
  error UserEntityNotExists();

  /**
   * @dev Throws where a particular type of `EntityType` is required and another is provided
   */
  error IncorrectEntityType();

  /**
   * @dev Enum which containes all types of entities
   *
   * None - not type of entity
   */
  enum EntityType {
    None,
    UserEntity,
    CompanyEntity,
    ProjectEntity
  }

  /**
   * @dev Emitted when updated `UpgradeableBeacon` implementation address by `EntityType`
   */
  event UpdatedUpgradeableBeacon(EntityType indexed entityType, address indexed newBeacon);

  /**
   * @dev Emitted when created new entity
   */
  event CreatedNewEntity(
    address indexed sender,
    uint256 indexed id,
    address indexed entityOwner,
    address entity,
    EntityType entityType
  );

  /**
   * @dev Emitted when `owner` is addred to owners of `UserEntity`.
   */
  event AddedOwnerOfEntity(address indexed newOwner);

  /**
   * @dev Emitted when `owner` is removed from `UserEntity`.
   */
  event RemovedOwnerOfEntity(address indexed owner);

  /**
   * @dev Initializes the contract setting and owner
   *
   * The caller will become the owner
   *
   * Requirements:
   *
   * - All parameters be not equal ZERO_ADDRESS
   */
  function initialize(
    address contractsRegistry_,
    address userEntityBeacon_,
    address companyEntityBeacon_,
    address projectEntityBeacon_
  ) external;

  /**
   * @dev Update new `UpgradeableBeacon` by `newBeacon_` implementation by `entityType_`
   *
   * Note this change will affect only the deploy of new Entities
   *
   * Requirements:
   *
   * - can only be called by owner
   * - `newBeacon_` must be not equal: `ZERO_ADDRESS`
   * - `entityType_` should be correct
   *
   * Emit a {UpdatedUpgradeableBeacon} event.
   */
  function updateUpgradeableBeacon(EntityType entityType_, address newBeacon_)
    external;

  /**
   * @dev Create new Entity contract by `type_` for caller or caller's UserEntity
   *
   * If user want create `ProjectEntity` or `CompanyEntity` entity, he need first
   * create `UserEntity`
   *
   * Sender's `UserEntity` will owner for new  `ProjectEntity` or `CompanyEntity`
   * deployed by sender
   *
   * Requirements:
   *
   * - can only be called with correct proof of permisison on createEntity
   * from {ISingleSignEntityStrategy-trustedSigner}
   * - should provide correct EntityType
   * - user can create only one UserEntity which he will is owner
   *
   * Return a deployed address.
   */
  function createEntity(
    EntityType type_,
    uint256 id_,
    uint256 nonce_,
    uint256 deadline_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) external returns (address entity);

  /**
   * @dev Add owner to UserEntity
   *
   * Requirements:
   *
   * - can only be called by registered `UserEntity`
   * - `newEntityOwner_` should not have another UserEntity
   *
   * Emit a {AddedOwnerOfEntity} event.
   */
  function addOwnerToUserEntity(address newEntityOwner_) external;

  /**
   * @dev Remove owner from UserEntity
   *
   * Requirements:
   *
   * - can only be called by registered `UserEntity`
   * - `entityOwner_` should be active owner of `UserEntity`
   *
   * Emit a {RemovedOwnerOfEntity} event.
   */
  function removeOwnerFromUserEntity(address entityOwner_) external;

  /**
   * @dev Retutn `EntityType` by address
   *
   * if `EntityType` is more than `EntityType.None` then it's
   * means that address is registered
   */
  function entityRegister(address entity_) external view returns (EntityType);

  /**
   * @dev Return `UserEntity` address by `owner_`
   */
  function ownersOfUserEntity(address owner_) external view returns (address);

  /**
   * @dev Returns the status of whether the `user_` have `UserEntity`
   *
   * Returns types:
   * - `true` - if `user_` have UserEntity
   * - `false` - if `user_` not have UserEntity
   */
  function isOwnerOfUserEntity(address user_) external view returns (bool);
}