//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface ILockTOSDividendProxy {
    /// @dev Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external;

    /// @dev Set implementation contract
    /// @param _impl New implementation contract address
    function upgradeTo(address _impl) external;

    /// @dev view implementation address
    /// @return the logic address
    function implementation() external view returns (address);

    /// @dev initialize
    function initialize(address _lockTOS, uint256 _epochUnit) external;
}