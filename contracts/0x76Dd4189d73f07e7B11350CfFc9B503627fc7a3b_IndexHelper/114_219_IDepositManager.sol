// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

interface IDepositManager {
    /// @notice Adds vToken to vTokens list
    /// @param _vToken Address of vToken
    function addVToken(address _vToken) external;

    /// @notice Removes vToken from vTokens list
    /// @param _vToken Address of vToken
    function removeVToken(address _vToken) external;

    /// @notice Sets deposit interval
    /// @param _interval deposit interval
    function setDepositInterval(uint32 _interval) external;

    /// @notice Sets maximum loss
    /// @dev Max loss range is [0 - 10_000]
    /// @param _maxLoss Maximum loss allowed
    function setMaxLoss(uint16 _maxLoss) external;

    /// @notice Updates deposits for vTokens
    function updateDeposits() external;

    /// @notice Address of Registry
    /// @return Returns address of Registry
    function registry() external view returns (address);

    /// @notice Maximum loss allowed during depositing and withdrawal
    /// @return Returns maximum loss allowed
    function maxLossInBP() external view returns (uint16);

    /// @notice Deposit interval
    /// @return Returns deposit interval
    function depositInterval() external view returns (uint32);

    /// @notice Last deposit timestamp of given vToken address
    /// @param _vToken Address of vToken
    /// @return Returns last deposit timestamp
    function lastDepositTimestamp(address _vToken) external view returns (uint96);

    /// @notice Checks if deposits can be updated
    /// @return Returns if deposits can be updated
    function canUpdateDeposits() external view returns (bool);

    /// @notice Checks if vTokens list contains vToken
    /// @param _vToken Address of vToken
    /// @return Returns if vTokens list contains vToken
    function containsVToken(address _vToken) external view returns (bool);
}