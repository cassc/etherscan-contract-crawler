//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ITPLRevealedParts} from "../../TPLRevealedParts/ITPLRevealedParts.sol";

/// @title ITPLMechOrigin
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Interface for TPLMechOrigin fetcher
interface ITPLMechOrigin {
    struct TPLPartOrigin {
        uint256 partId; // ID in the TPLRevealedParts contract
        ITPLRevealedParts.TokenData data;
    }

    struct MechOrigin {
        TPLPartOrigin[] parts;
        uint256 afterglow;
    }

    /// @notice returns all TPLRevealedParts IDs & TPLAfterglow ID used in crafting a Mech
    /// @param mechData the Mech extra data allowing to find its origin
    /// @return an array with the parts ids used
    /// @return the afterglow id
    function getMechPartsIds(uint256 mechData) external view returns (uint256[] memory, uint256);

    /// @notice returns all TPL Revealed Parts IDs (& their TokenData) used in crafting a Mech
    /// @param partsIds the parts ids
    /// @return an array containings each partsIds token data
    function getPartsOrigin(uint256[] memory partsIds) external view returns (TPLPartOrigin[] memory);

    /// @notice returns all TPL Revealed Parts IDs (& their TokenData) used in crafting a Mech
    /// @param mechData the Mech extra data allowing to find its origin
    /// @return a MechOrigin with all parts origin & afterglow
    function getMechOrigin(uint256 mechData) external view returns (MechOrigin memory);
}