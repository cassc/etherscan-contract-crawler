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
// ======================= EntityFactory ===============================
// =====================================================================

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./entities/interfaces/IUserEntity.sol";
import "./entities/interfaces/IProjectEntity.sol";
import "./entities/interfaces/ICompanyEntity.sol";
import "./interfaces/IWhiteList.sol";
import "./interfaces/IEntityFactory.sol";
import "./strategies/interfaces/ISingleSignEntityStrategy.sol";
import "./interfaces/IContractsRegistry.sol";
import { WHITE_LIST_CONTRACT_CODE, ENTITY_STRATEGY_CONTRACT_CODE } from "./Constants.sol";

/**
 * @title EntityFactory
 * @author milestoneBased R&D Team
 *
 * @dev contract which implemented of the {IEntityFactory} interface.
 * The contract is a register and a factory for creating entities contracts
 *
 * The contract inherits {OwnableUpgradeable} from the OpenZeppelin contracts
 * as it is also upgradeable for future expansion
 *
 * WARNING: The `Owner` of the contract has very important rights to change
 * contracts in the system, be as careful as possible with him,
 * we recommend using `MultiSign` for owner address
 */
contract EntityFactory is IEntityFactory, OwnableUpgradeable {
  /**
   * @dev Variable for storing contractsRegistry address
   */
  IContractsRegistry public contractsRegistry;

  /**
   * @dev Mapping for storing the `EntityType` by address
   *
   * if `EntityType` is more than `EntityType.None` then it's
   * means that address is registered
   */
  mapping(address => EntityType) public override entityRegister;

  /**
   * @dev Mapping for storing pinning the user to the UserEntity
   */
  mapping(address => address) public override ownersOfUserEntity;

  /**
   * @dev Mapping for storing the `UpgradeableBeacon` implementation by `EntityType`
   */
  mapping(EntityType => address) public upgradeableBeaconByType;

  /**
   * @dev Throws if called by any account other than the registered `UserEntity`.
   */
  modifier onlyUserEntity() {
    if (entityRegister[_msgSender()] != EntityType.UserEntity) {
      revert IncorrectEntityType();
    }
    _;
  }

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
  ) external virtual override initializer {
    if (
      userEntityBeacon_ == address(0) ||
      companyEntityBeacon_ == address(0) ||
      projectEntityBeacon_ == address(0) ||
      contractsRegistry_ == address(0)
    ) {
      revert ZeroAddress();
    }

    __Ownable_init();

    upgradeableBeaconByType[EntityType.UserEntity] = userEntityBeacon_;
    upgradeableBeaconByType[EntityType.CompanyEntity] = companyEntityBeacon_;
    upgradeableBeaconByType[EntityType.ProjectEntity] = projectEntityBeacon_;

    contractsRegistry = IContractsRegistry(contractsRegistry_);
  }

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
    external
    virtual
    override
    onlyOwner
  {
    if (newBeacon_ == address(0)) {
      revert ZeroAddress();
    }
    if (entityType_ == EntityType.None) {
      revert IncorrectEntityType();
    }
    upgradeableBeaconByType[entityType_] = newBeacon_;
    emit UpdatedUpgradeableBeacon(entityType_, newBeacon_);
  }

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
  ) external virtual override returns (address entity) {
    if (type_ == EntityType.None) {
      revert IncorrectEntityType();
    }

    _checkSignature(_msgSender(), id_, type_, nonce_, deadline_, v_, r_, s_);

    address entityOwner = _msgSender();
    address userEntity = ownersOfUserEntity[_msgSender()];
    if (type_ == EntityType.UserEntity) {
      if (userEntity != address(0)) {
        revert EntityAlreadyExistsForUser();
      }
    } else {
      if (userEntity == address(0)) {
        revert UserEntityNotExists();
      }
      entityOwner = userEntity;
    }

    entity = _createEntity(entityOwner, id_, type_);
  }

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
  function addOwnerToUserEntity(address newEntityOwner_)
    external
    virtual
    override
    onlyUserEntity
  {
    if (ownersOfUserEntity[newEntityOwner_] != address(0)) {
      revert EntityAlreadyExistsForUser();
    }

    ownersOfUserEntity[newEntityOwner_] = _msgSender();
    emit AddedOwnerOfEntity(newEntityOwner_);
  }

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
  function removeOwnerFromUserEntity(address entityOwner_)
    external
    virtual
    override
    onlyUserEntity
  {
    delete ownersOfUserEntity[entityOwner_];
    emit RemovedOwnerOfEntity(entityOwner_);
  }

  /**
   * @dev Returns the status of whether the `user_` have `UserEntity`
   *
   * Returns types:
   * - `true` - if `user_` have UserEntity
   * - `false` - if `user_` not have UserEntity
   */
  function isOwnerOfUserEntity(address user_)
    external
    view
    virtual
    override
    returns (bool)
  {
    return ownersOfUserEntity[user_] != address(0);
  }

  /**
   * @dev Deploy new `BeaconProxy` by providing  `entityTyp`, initialize,
   * setup whitelist and ownership. Also, returns address deployed contract
   *
   * [IMPORTANT]
   * ===
   * Internal function without access restriction and ownersOfUserEntity checker
   * ===
   *
   * Emit a {CreatedNewEntity} event.
   */
  function _createEntity(
    address entityOwner_,
    uint256 id_,
    EntityType entityType_
  ) internal virtual returns (address entity) {
    bytes memory initializeData = abi.encodeWithSelector(
      IUserEntity.initialize.selector,
      entityOwner_,
      address(contractsRegistry)
    );
    entity = address(
      new BeaconProxy(upgradeableBeaconByType[entityType_], initializeData)
    );

    IWhiteList(contractsRegistry.getContractByKey(WHITE_LIST_CONTRACT_CODE))
      .addNewAddress(entity);

    entityRegister[entity] = entityType_;
    ownersOfUserEntity[entityOwner_] = entity;

    emit CreatedNewEntity(_msgSender(), id_, entityOwner_, entity, entityType_);
  }

  /**
   * @dev Checks the correctness of the signature
   * for the permission to create a new entity
   *
   * See {ISingleSignEntityStrategy-useSignature}
   */
  function _checkSignature(
    address entityOwner_,
    uint256 id_,
    EntityType entityType_,
    uint256 nonce_,
    uint256 deadline_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) internal virtual {
    ISingleSignEntityStrategy.Entity memory entity = ISingleSignEntityStrategy
      .Entity(entityOwner_, address(this), uint256(entityType_), id_);

    ISingleSignEntityStrategy(
      contractsRegistry.getContractByKey(ENTITY_STRATEGY_CONTRACT_CODE)
    ).useSignature(entity, deadline_, nonce_, v_, r_, s_);
  }
}