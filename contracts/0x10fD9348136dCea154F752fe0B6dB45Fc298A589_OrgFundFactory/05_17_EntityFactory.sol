//SPDX-License-Identifier: BSD 3-Clause
pragma solidity >=0.8.0;

import "./Registry.sol";
import "./Entity.sol";

/**
 * @notice EntityFactory contract inherited by OrgFundFactory and future factories.
 */
abstract contract EntityFactory {

    /// @notice _registry The registry to host the Entity.
    Registry public immutable registry;

    /// @notice Emitted when an Entity is deployed.
    event EntityDeployed(address indexed entity, uint8 indexed entityType, address indexed entityManager);

    /**
     * @param _registry The registry to host the Entity.
     */
    constructor(Registry _registry) {
        registry = _registry;
    }
}