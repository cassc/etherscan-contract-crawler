// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Libraries
import {LibSignatures} from "../../libraries/LibSignatures.sol";

/**
 * @notice Contains party methods that can be called by any member of the party
 * @dev Permissioned Party actions
 */
interface IPartyMemberActions {
    /**
     * @notice Deposits into the party
     * @dev The user must be a member and the party must be opened
     * @param user User address that will be making the deposit
     * @param amount Deposit amount in denomination asset
     * @param allocation Desired allocation of the deposit
     * @param approval Verified sentinel signature of the desired deposit
     */
    function deposit(
        address user,
        uint256 amount,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external;

    /**
     * @notice Withdraw funds from the party
     * @dev The user must be a member
     * @param amountPT Amount of PartyTokens of the requester to withdraw
     * @param allocation Desired allocation of the withdraw
     * @param approval Verified sentinel signature of the desired withdraw
     * @param liquidate Whether to liquidate assets (convert all owned assets into denomination asset) or to withdraw assets as it is
     */
    function withdraw(
        uint256 amountPT,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external;

    /**
     * @notice Leave the party (withdraw all funds and remove membership)
     * @dev The user must be a member
     * @param allocation Desired allocation of the withdraw
     * @param approval Verified sentinel signature of the desired withdraw
     * @param liquidate Whether to liquidate assets (convert all owned assets into denomination asset) or to withdraw assets as it is
     */
    function leaveParty(
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external;
}