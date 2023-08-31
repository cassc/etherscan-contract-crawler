// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Interfaces/IWhitelist.sol";

abstract contract Whitelist is IWhitelist, AccessControl {
    bytes32 internal constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");
    bytes32 internal constant PARTICIPANT_ROLE = keccak256("PARTICIPANT_ROLE");

    function addToWhitelist(
        address participant
    ) public virtual onlyRole(WHITELISTER_ROLE) {
        _grantRole(PARTICIPANT_ROLE, participant);
    }

    function removeFromWhitelist(
        address participant
    ) public virtual onlyRole(WHITELISTER_ROLE) {
        _revokeRole(PARTICIPANT_ROLE, participant);
    }

    function addWhitelister(
        address whitelister
    ) public virtual onlyRole(WHITELISTER_ROLE) {
        _grantRole(WHITELISTER_ROLE, whitelister);
    }

    function removeWhitelister(
        address whitelister
    ) public virtual onlyRole(WHITELISTER_ROLE) {
        require(
            whitelister != _msgSender(),
            "Whitelist: cannot remove whitelister role yourself"
        );
        _revokeRole(WHITELISTER_ROLE, whitelister);
    }

    function isWhitelister(address participant) public view returns (bool) {
        return hasRole(WHITELISTER_ROLE, participant);
    }

    function isWhitelisted(address participant) public view returns (bool) {
        return hasRole(PARTICIPANT_ROLE, participant);
    }
}