// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {IndieV1Errors} from "./IndieV1Errors.sol";
import {IndieV1Events} from "./IndieV1Events.sol";

interface IIndieV1 is IndieV1Errors, IndieV1Events {
    /**
     * @notice Renounces ownership of contract
     * @dev Using this function bricks all owner-controlled functionality by
     * assigning ownership to the null address.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s owner role.
     *
     * Emits a {RoleGranted} event.
     * Emits a {RoleRevoked} event.
     * Emits a {OwnershipRenounced} event.
     */
    function renounceOwnership() external;

    /**
     * @notice Transfer ownership to new owner
     * @param newOwner The address of the new contract owner
     * @dev Grants the owner role to `newOwner` and revokes it from the caller.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s owner role.
     * - the `newOwner` cannot have ``role``'s admin role.
     *
     * Emits a {RoleGranted} event.
     * Emits a {RoleRevoked} event.
     * Emits a {OwnershipTransferred} event.
     */
    function transferOwnership(address newOwner) external;
}