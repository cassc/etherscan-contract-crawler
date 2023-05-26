// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import {OwnableBase} from "./OwnableBase.sol";

interface IJumpPort {
    function ownerOf(address tokenAddress, uint256 tokenId) external view returns (address owner);

    function isDeposited(address tokenAddress, uint256 tokenId) external view returns (bool);

    function getApproved(address tokenAddress, uint256 tokenId) external view returns (address copilot);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function lockToken(address tokenAddress, uint256 tokenId) external;

    function unlockToken(address tokenAddress, uint256 tokenId) external;

    function unlockAllTokens(bool isOverridden) external;

    function blockExecution(bool isBlocked) external;
}

abstract contract Portal is OwnableBase {
    IJumpPort public JumpPort;
    bytes32 public constant UNLOCK_ROLE = keccak256("UNLOCK_ROLE");

    constructor(address jumpPortAddress) {
        JumpPort = IJumpPort(jumpPortAddress);
    }

    /**
     * @dev Allow current administrators to be able to grant/revoke unlock role to other addresses.
     */
    function setUnlockRole(address account, bool canUnlock) public onlyRole(ADMIN_ROLE) {
        roles[UNLOCK_ROLE][account] = canUnlock;
        emit RoleChange(UNLOCK_ROLE, account, canUnlock, msg.sender);
    }

    /**
     * @dev Mark locks held by this portal as void or not.
     * Allows for portals to have a degree of self-governance; if the administrator(s) of a portal
     * realize something is wrong and wish to allow all tokens locked by that portal as void, they're
     * able to indicate that to the JumpPort, without needing to invlove JumpPort governance.
     */
    function unlockAllTokens(bool isOverridden) public onlyRole(ADMIN_ROLE) {
        JumpPort.unlockAllTokens(isOverridden);
    }

    /**
     * @dev Prevent this Portal from calling `executeAction` on the JumpPort.
     * Intended to be called in the situation of a large failure of an individual Portal's operation,
     * as a way for the Portal itself to indicate it has failed, and arbitrary contract calls should not
     * be allowed to originate from it.
     *
     * This function only allows Portals to enable/disable their own execution right.
     */
    function blockExecution(bool isBlocked) public onlyRole(ADMIN_ROLE) {
        JumpPort.blockExecution(isBlocked);
    }
}