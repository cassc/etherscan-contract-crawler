// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPauserRead {
    /// @notice Flag indicating if staking is paused.
    function isStakingPaused() external view returns (bool);

    /// @notice Flag indicating if unstake requests are paused.
    function isUnstakeRequestsAndClaimsPaused() external view returns (bool);

    /// @notice Flag indicating if initiate validators is paused
    function isInitiateValidatorsPaused() external view returns (bool);

    /// @notice Flag indicating if submit oracle records is paused.
    function isSubmitOracleRecordsPaused() external view returns (bool);

    /// @notice Flag indicating if allocate ETH is paused.
    function isAllocateETHPaused() external view returns (bool);
}

interface IPauserWrite {
    /// @notice Pauses all actions.
    function pauseAll() external;
}

interface IPauser is IPauserRead, IPauserWrite {}