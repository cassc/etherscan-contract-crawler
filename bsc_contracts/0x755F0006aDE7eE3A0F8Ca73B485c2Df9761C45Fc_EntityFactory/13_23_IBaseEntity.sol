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
// ======================= IBaseEntity =================================
// =====================================================================

import "./IOwnerManager.sol";

/**
 * @title IBaseEntity
 * @author milestoneBased R&D Team
 *
 * @dev External interface of `BaseEntity`
 */
interface IBaseEntity is IOwnerManager {

  /**
   * @dev Throws if user approves or transfer token for 0 amount.
   */
  error ZeroValue();

  /**
   * @dev Emitted when one from owners called {IBaseEntity-withdrawFromEntity}.
   */
  event Withdrawn(
    address indexed sender,
    address token,
    address indexed recipient,
    uint256 amount
  );

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
  function withdrawFromEntity(
    address token_,
    uint256 amount_,
    address payable recipient_
  ) external;

  /**
   * @dev Approve amounts of tokens for use for `spender_`.
   *
   * - can only be called by the one from owner
   *
   */
  function approve(
    address token_,
    address spender_,
    uint256 amount_
  ) external;

  /**
   * @dev Increase amount of tokens to use for `spender_`.
   *
   * - can only be called by the one from owner
   *
   */
  function increaseAllowance(
    address token_,
    address spender_,
    uint256 amount_
  ) external;

  /**
   * @dev Decrease amount of tokens to use for `spender_`.
   *
   * - can only be called by the one from owner
   *
   */
  function decreaseAllowance(
    address token_,
    address spender_,
    uint256 amount_
  ) external;

}