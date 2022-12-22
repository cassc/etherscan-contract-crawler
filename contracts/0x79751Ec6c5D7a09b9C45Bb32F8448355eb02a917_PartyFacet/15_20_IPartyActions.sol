// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Libraries
import {LibSignatures} from "../../libraries/LibSignatures.sol";

/**
 * @notice Contains party methods that can be called by anyone
 * @dev Permissionless Party actions
 */
interface IPartyActions {
    /**
     * @notice Joins and deposits into the party
     * @dev For private parties, the joiner must have an accepted join request by a manager.
     *      The user must not be a member and the party must be opened
     * @param user User address that will be joining the party
     * @param amount Deposit amount in denomination asset
     * @param allocation Desired allocation of the deposit
     * @param approval Verified sentinel signature of the desired deposit
     */
    function joinParty(
        address user,
        uint256 amount,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external;
}