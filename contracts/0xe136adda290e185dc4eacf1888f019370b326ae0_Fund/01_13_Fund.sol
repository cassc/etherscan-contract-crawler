//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import { Registry } from "./Registry.sol";
import { Entity } from "./Entity.sol";

/**
 * @notice Fund entity
 */
contract Fund is Entity {

    /**
     * @notice One time method to be called at deployment to configure the contract. Required so Fund
     * contracts can be deployed as minimal proxies (clones).
     * @param _registry The registry to host the Fund Entity.
     * @param _manager The address of the Fund's manager.
     */
    function initialize(Registry _registry, address _manager) public {
        // Call to Entity's initialization function ensures this can only be called once
        __initEntity(_registry, _manager);
    }

    /**
     * @inheritdoc Entity
     */
    function entityType() public pure override returns (uint8) {
        return 2;
    }
}