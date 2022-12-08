// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

/**
 * @title IBhavishAdministrator
 */

interface IBhavishAdministrator {
    /**
     * @dev Emitted when Treasury is claimed by the admin
     * @param admin Address of the admin
     * @param amount Amount claimed by the admin
     */
    event TreasuryClaim(address indexed admin, uint256 amount);

    /**
     * @dev Claim the treasury amount. Can be performed only by admin
     */
    function claimTreasury() external;
}