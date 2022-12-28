// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Libraries
import {LibSignatures} from "../../libraries/LibSignatures.sol";
import {PartyInfo} from "../../libraries/LibAppStorage.sol";

/**
 * @notice Contains party methods that can be called by any manager of the Party
 * @dev Permissioned Party actions
 */
interface IPartyManagerActions {
    /**
     * @notice Swap a token with the party's fund
     * @dev The user must be a manager. Only swaps a single asset.
     * @param allocation Desired allocation of the swap
     * @param approval Verified sentinel signature of the desired swap
     */
    function swapToken(
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external;

    /**
     * @notice Kick a member from the party
     * @dev The user must be a manager
     * @param kickingMember address of the member to be kicked
     * @param allocation desired allocation of the withdraw
     * @param approval verified sentinel signature of the desired kick
     * @param liquidate whether to liquidate assets (convert all owned assets into denomination asset) or to transfer assets as it is
     */
    function kickMember(
        address kickingMember,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external;
}