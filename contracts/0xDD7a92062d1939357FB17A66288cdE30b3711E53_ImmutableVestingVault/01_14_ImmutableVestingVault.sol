// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./ARCDVestingVault.sol";

import { IVV_ImmutableGrants } from "./errors/Governance.sol";

/**
 * @title ImmutableVestingVault
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract is a vesting vault for the Arcade token. Once a grant is added by the
 * contract manager, it cannot be modified or revoked.
 *
 * @dev See the ARCDVestingVault contract for the full vesting vault implementation.
 */
contract ImmutableVestingVault is ARCDVestingVault {
    /**
     * @notice Deploys a new vesting vault, setting relevant immutable variables
     *         and granting management power to a defined address.
     *
     * @param _token              The ERC20 token to grant.
     * @param _stale              Stale block used for voting power calculations
     * @param manager_            The address of the manager.
     * @param timelock_           The address of the timelock.
     */
    constructor(
        IERC20 _token,
        uint256 _stale,
        address manager_,
        address timelock_
    ) ARCDVestingVault(_token, _stale, manager_, timelock_) {}

    /**
     * @notice All grants are immutable and cannot be revoked.
     *
     * @dev This function overrides the parent revokeGrant function and always reverts.
     */
    function revokeGrant(address) public pure override {
        revert IVV_ImmutableGrants();
    }
}