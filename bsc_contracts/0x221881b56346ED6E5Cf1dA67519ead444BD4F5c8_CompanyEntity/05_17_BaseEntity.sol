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
// ======================= BaseEntity ==================================
// =====================================================================

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./OwnerManager.sol";
import "../interfaces/IBaseEntity.sol";
import "../../interfaces/IContractsRegistry.sol";
import "../../interfaces/IEntityFactory.sol";
import { ENTITY_FACTORY_CONTRACT_CODE } from "../../Constants.sol";

/**
 * @title BaseEntity
 * @author milestoneBased R&D Team
 *
 * @dev abstract contract which implemented of the {IBaseEntity} interface. A contract
 * that implements standard entity methods for withdraw and approve tokens or coins.
 *
 * The contract inherits {OwnerManager} for access control
 */
abstract contract BaseEntity is IBaseEntity, OwnerManager {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address payable;

  /**
   * @dev Variable for storing contractsRegistry address
   */
  IContractsRegistry public contractsRegistry;

  /**
   * @dev Initializes the contract setting the owner and contracts registry.
   *
   * Requirements:
   *
   * - `owner_` must be not equal: `ZERO_ADDRESS`, `_SENTINEL_OWNERS`, this contract address
   * - `contractsRegistry_` must be not equal: `ZERO_ADDRESS`
   *
   */
  // solhint-disable-next-line
  function __BaseEntity_init(address owner_, address contractsRegistry_)
    internal
    virtual
    onlyInitializing
  {
    if (contractsRegistry_ == address(0)) {
      revert ZeroAddress();
    }
    __OwnerManager_init(owner_);
    contractsRegistry = IContractsRegistry(contractsRegistry_);
  }

  /**
   * @dev Transfers tokens or coins from contract to `recipient_`.
   *
   * @param token_ address of ERC20 token which want transfer
   * can be set zero then will transfer coin from the contract
   *
   * Requirements:
   *
   * - can only be called by the one from owner
   *
   * Emits a {Withdrawn} event.
   */
  // solhint-disable-next-line ordering
  function withdrawFromEntity(
    address token_,
    uint256 amount_,
    address payable recipient_
  ) external virtual override onlyOwner {
    if (amount_ == 0) {
      revert ZeroValue();
    }
    if (recipient_ == address(0)) {
      revert ZeroAddress();
    }
    if (token_ == address(0)) {
      recipient_.sendValue(amount_);
    } else {
      IERC20Upgradeable(token_).safeTransfer(recipient_, amount_);
    }
    emit Withdrawn(_msgSender(), token_, recipient_, amount_);
  }

  /**
   * @dev Approve amounts of tokens for use for `recipient_`.
   *
   * - can only be called by the one from owner
   *
   */
  function approve(
    address token_,
    address spender_,
    uint256 amount_
  ) external virtual override onlyOwner {
    if (spender_ == address(0)) {
      revert ZeroAddress();
    }
    IERC20Upgradeable(token_).safeApprove(spender_, amount_);
  }

  /**
   * @dev increase allowance for amounts of tokens for use for `recipient_`.
   *
   * - can only be called by the one from owner
   *
   */
  function increaseAllowance(
    address token_,
    address spender_,
    uint256 amount_
  ) external virtual override onlyOwner {
    if (spender_ == address(0)) {
      revert ZeroAddress();
    }
    if (amount_ == 0) {
      revert ZeroValue();
    }
    IERC20Upgradeable(token_).safeIncreaseAllowance(spender_, amount_);
  }

  /**
   * @dev decrease allowance for amounts of tokens for use for `recipient_`.
   *
   * - can only be called by the one from owner
   *
   */
  function decreaseAllowance(
    address token_,
    address spender_,
    uint256 amount_
  ) external virtual override onlyOwner {
    if (spender_ == address(0)) {
      revert ZeroAddress();
    }
    if (amount_ == 0) {
      revert ZeroValue();
    }
    IERC20Upgradeable(token_).safeDecreaseAllowance(spender_, amount_);
  }

  /**
   * @dev Returns actual `EntityFactory` contract from contractRegistry
   */
  function _getEntityFactory() internal view returns (IEntityFactory factory) {
    factory = IEntityFactory(
      contractsRegistry.getContractByKey(ENTITY_FACTORY_CONTRACT_CODE)
    );
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private ___gap;
}