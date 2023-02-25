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
// ======================= IExpandedEntity =============================
// =====================================================================

import "./IBaseEntity.sol";

/**
 * @title IExpandedEntity
 * @author milestoneBased R&D Team
 *
 * @dev  External interface of `ExpandedEntity`
 */
interface IExpandedEntity is IBaseEntity {
  /**
   * @dev Throws where a particular type of {IEntityFactory.EntityType} is required and another is provided
   *
   * See {IEntityFactory.EntityType}
   */
  error IncorrectEntityType();
}