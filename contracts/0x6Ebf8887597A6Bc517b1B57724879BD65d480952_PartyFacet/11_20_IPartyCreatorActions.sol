// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Libraries
import {LibSignatures} from "../../libraries/LibSignatures.sol";
import {PartyInfo} from "../../libraries/LibAppStorage.sol";

/**
 * @notice Contains party methods that can be called by the creator of the Party
 * @dev Permissioned Party actions
 */
interface IPartyCreatorActions {
    /**
     * @notice Close the party
     * @dev The user must be a creator and the party must be opened
     */
    function closeParty() external;

    /**
     * @notice Edits the party information
     * @dev The user must be a creator
     * @param _partyInfo PartyInfo struct
     */
    function editPartyInfo(PartyInfo memory _partyInfo) external;

    /**
     * @notice Handles the managers for the party
     * @dev The user must be the creator of the party
     * @param manager Address of the user
     * @param setManager Whether to set the user as manager or remove it
     */
    function handleManager(address manager, bool setManager) external;
}