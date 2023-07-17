//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import { Registry } from "./Registry.sol";
import { Entity } from "./Entity.sol";

/**
 * @notice This contract controls the Org entity.
 */
contract Org is Entity {

    /// @notice Tax ID of org
    bytes32 public orgId;

    /**
     * @notice One time method to be called at deployment to configure the contract. Required so Org
     * contracts can be deployed as minimal proxies (clones).
     * @param _registry The registry to host the Org Entity.
     * @param _orgId The Org's ID for tax purposes.
     * @dev The `manager` of the Org is initially set to the zero address and will be updated by role pending an off-chain claim.
     */
    function initialize(Registry _registry, bytes32 _orgId) public {
        // Call to Entity's initializer ensures this can only be called once.
        __initEntity(_registry, address(0));
        orgId = _orgId;
    }

    function setOrgId(bytes32 _orgId) requiresAuth external {
        orgId = _orgId;
    }

    /**
     * @inheritdoc Entity
     */
    function entityType() public pure override returns (uint8) {
        return 1;
    }
}