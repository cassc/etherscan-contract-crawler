// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title ITPLBodyParts
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Interface for body parts helpers
///
interface ITPLBodyParts {
    error UnknownPart();

    enum BodyParts {
        ARM,
        HEAD,
        BODY,
        LEGS,
        ENGINE
    }

    enum BodyPartModel {
        ENFORCER,
        RAVAGER,
        BEHEMOTH,
        LUPIS,
        NEXUS
    }

    function getBodyPart(uint256 generationId, uint256 partId) external view returns (uint256);

    function getBodyPartModel(uint256 generationId, uint256 partId) external view returns (uint256);
}