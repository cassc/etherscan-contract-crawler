// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ICedarPausableV0 {
    /// @dev Pause claim functionality.
    function pauseClaims() external;

    /// @dev Un-pause claim functionality.
    function unpauseClaims() external;

    /// @dev Event emitted when claim functionality is paused/un-paused.
    event ClaimPauseStatusUpdated(bool pauseStatus);
}

interface ICedarPausableV1 {
    /// @dev Pause / Un-pause claim functionality.
    function setClaimPauseStatus(bool _pause) external;

    /// @dev Event emitted when claim functionality is paused/un-paused.
    event ClaimPauseStatusUpdated(bool pauseStatus);
}

interface IRestrictedPausableV0 {
    /// @dev Pause / Un-pause claim functionality.
    function setClaimPauseStatus(bool _pause) external;
}

interface IRestrictedPausableV1 is IRestrictedPausableV0 {
    /// @dev Event emitted when claim functionality is paused/un-paused.
    event ClaimPauseStatusUpdated(bool pauseStatus);
}

interface IPublicPausableV0 {
    /// @dev returns the pause status of the drop contract.
    function getClaimPauseStatus() external view returns (bool pauseStatus);
}

interface IDelegatedPausableV0 {
    /// @dev returns the pause status of the drop contract.
    function getClaimPauseStatus() external view returns (bool pauseStatus);
}