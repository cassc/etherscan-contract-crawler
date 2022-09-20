/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../lib/Facts.sol";
import "../RelicTokenConfigurable.sol";
import "../Reliquary.sol";
import "../interfaces/ITokenURI.sol";

/**
 * @title Attendance Artifact Token
 * @author Theori, Inc.
 * @notice Configurable soul-bound tokens issued only to those that can prove they
 *         attended events.
 */
contract AttendanceArtifact is RelicTokenConfigurable {
    Reliquary immutable reliquary;

    constructor(Reliquary _reliquary) RelicToken() Ownable() {
        reliquary = _reliquary;
    }

    /**
     * @inheritdoc RelicToken
     * @dev High 32 bits of data are URI provider information that is ignored here
     */
    function hasToken(address who, uint96 data) internal view override returns (bool result) {
        uint64 eventId = uint64(data);
        FactSignature sig = Facts.toFactSignature(
            Facts.NO_FEE,
            abi.encode("EventAttendance", "EventID", eventId)
        );
        (result, ) = reliquary.verifyFactVersionNoFee(who, sig);
    }

    /// @inheritdoc IERC721Metadata
    function name() external pure override returns (string memory) {
        return "Attendance Artifact";
    }

    /// @inheritdoc IERC721Metadata
    function symbol() external pure override returns (string memory) {
        return "RAA";
    }
}