// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


interface ILockTOSDividend {
    /// @dev Claim batch
    function claimBatch(address[] calldata _tokens) external;

    /// @dev Claim
    function claim(address _token) external;

    /// @dev Claim up to `_timestamp`
    function claimUpTo(address _token, uint256 _timestamp) external;

    /// @dev Epoch to timestamp
    // function epochToTimestamp(uint256 _epoch) external view returns (uint256);

    /// @dev Distribute
    // function redistribute(address _token, uint256 _weeklyEpoch) external;

    /// @dev Distribute
    function distribute(address _token, uint256 _amount) external;

    /// @dev getCurrentWeeklyEpochTimestamp
    function getCurrentWeeklyEpochTimestamp() external view returns (uint256);

    /// @dev ifDistributionPossible
    function ifDistributionPossible() external view returns (bool);

    /// @dev getAvailableClaims
    function getAvailableClaims(address _account) external view returns (address[] memory claimableTokens, uint256[] memory claimableAmounts);

    /// @dev Get weekly epoch for `_timestamp`
    function getWeeklyEpoch(uint256 _timestamp) external view returns (uint256);

    /// @dev Get current weekly epoch
    function getCurrentWeeklyEpoch() external view returns (uint256);

    /// @dev Returns tokens per week at `_timestamp`
    function tokensPerWeekAt(address _token, uint256 _timestamp)
        external
        view
        returns (uint256);

    /// @dev Returns the last epoch claimed for `_lockId`
    function claimStartWeeklyEpoch(address _token, uint256 _lockId)
        external
        view
        returns (uint256);

    /// @dev Returns claimable amount
    function claimable(address _account, address _token) external view returns (uint256);

    /// @dev Returns claimable amount from `_timeStart` to `_timeEnd`
    function claimableForPeriod(address _account, address _token, uint256 _timeStart, uint256 _timeEnd) external view returns (uint256);
}