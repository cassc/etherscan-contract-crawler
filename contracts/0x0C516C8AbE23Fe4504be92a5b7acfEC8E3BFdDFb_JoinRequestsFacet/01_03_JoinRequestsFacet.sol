// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AppStorage, Modifiers, Announcement} from "../libraries/LibAppStorage.sol";

/// "User has already requested to join"
error AlreadyRequested();
/// "User join request is already accepted"
error RequestAlreadyAccepted();
/// "User join request is not found"
error RequestNotFound();

/**
 * @title JoinRequestsFacet
 * @author PartyFinance
 * @notice Facet that lets read, create, update and delete join requests.
 */
contract JoinRequestsFacet is Modifiers {
    /**
     * @notice Emitted when a user requests to join a private party
     * @param member Address of the user requesting to join
     */
    event JoinRequest(address member);

    /**
     * @notice Emitted when a join requests gets accepted or rejected
     * @param member Address of the user that requested to join
     * @param accepted Whether the request was accepted or rejected
     */
    event HandleJoinRequest(address member, bool accepted);

    /**
     * @notice Gets the party pending join requests
     * @return Array of join requests that are pending
     */
    function getJoinRequests() external view returns (address[] memory) {
        return s.joinRequests;
    }

    /**
     * @notice Checks if the pending join request was accepted
     * @return Whether if a given user has an accepted join request
     */
    function isAcceptedRequest(address user) external view returns (bool) {
        return s.acceptedRequests[user];
    }

    /**
     * @notice Requests to join a party
     * @dev Only non Party Members are the only allowed to request to join
     */
    function createJoinRequest() external notMember isAlive {
        if (s.acceptedRequests[msg.sender]) revert RequestAlreadyAccepted();
        for (uint256 i = 0; i < s.joinRequests.length; i++) {
            if (s.joinRequests[i] == msg.sender) {
                revert AlreadyRequested();
            }
        }
        s.joinRequests.push(msg.sender);
        emit JoinRequest(msg.sender);
    }

    /**
     * @notice Handles a join request to party
     * @dev Only Party Managers are the only allowed to handle requests
     * @param accepted True if request should be accepted. Otherwise, it's discarted
     * @param user Accound address of the request
     */
    function handleJoinRequest(bool accepted, address user)
        external
        onlyManager
        isAlive
    {
        if (s.acceptedRequests[user]) revert RequestAlreadyAccepted();
        // Search for the request
        bool found;
        for (uint256 i = 0; i < s.joinRequests.length; i++) {
            if (s.joinRequests[i] == user) {
                found = true;
                if (accepted) {
                    s.acceptedRequests[user] = true;
                }
                if (i < s.joinRequests.length - 1) {
                    s.joinRequests[i] = s.joinRequests[
                        s.joinRequests.length - 1
                    ];
                }
                s.joinRequests.pop();
                emit HandleJoinRequest(user, accepted);
            }
        }
        if (!found) revert RequestNotFound();
    }
}