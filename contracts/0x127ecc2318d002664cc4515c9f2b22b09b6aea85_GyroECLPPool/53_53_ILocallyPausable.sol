// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.
pragma solidity ^0.7.0;

interface ILocallyPausable {
    event PausedLocally();
    event UnpausedLocally();
    event PauseManagerChanged(address oldPauseManager, address newPauseManager);

    struct PauseParams {
        uint256 pauseWindowDuration;
        uint256 bufferPeriodDuration;
    }

    /// @notice Changes the account that is allowed to pause a pool.
    function changePauseManager(address _pauseManager) external;

    /// @notice Pauses the pool.
    /// Can only be called by the pause manager.
    function pause() external;

    /// @notice Unpauses the pool.
    /// Can only be called by the pause manager.
    function unpause() external;
}