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
// ======================= IUserEntity =================================
// =====================================================================

import "./IBaseEntity.sol";

/**
 * @title IUserEntity
 * @author milestoneBased R&D Team
 *
 * @dev External interface of `UserEntity`
 */
interface IUserEntity is IBaseEntity {
  /**
   * @dev Initializes the contract setting the owner_ and contractsRegistry_.
   *
   * Requirements:
   *
   * - `owner_` must be `UserEntity` contract
   * - `contractsRegistry_` must be not equal: `ZERO_ADDRESS`
   * - can be called only once
   */
  function initialize(address owner_, address contractsRegistry_) external;
}