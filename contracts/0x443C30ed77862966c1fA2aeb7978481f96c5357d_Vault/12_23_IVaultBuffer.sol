// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IVaultBuffer {
    event OpenDistribute();
    event CloseDistribute();

    /// @notice mint pending shares
    /// @param _sender user account address
    /// @param _amount mint amount
    function mint(address _sender, uint256 _amount) external payable;

    /// @notice transfer cash to vault
    /// @param _assets transfer token
    /// @param _amounts transfer token amount
    function transferCashToVault(address[] memory _assets, uint256[] memory _amounts) external;

    function openDistribute() external;

    function distributeWhenDistributing() external returns (bool);

    function distributeOnce() external returns (bool);

    function isDistributing() external view returns (bool);

    function getDistributeLimit() external view returns (uint256);

    function setDistributeLimit(uint256 _limit) external;
}