// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ITreasury {
    function withdrawToProjectWallet(address projectWallet, uint256 amount) external;

    function shutdown(bool _isShutdown) external;

    function viewFundsInTreasury() external view returns (uint256);

    function payRefund(address _to, uint256 _amount) external;

    function setProjectBalance(address _projectWallet, uint256 _balance) external;

    function moveFundsOutOfTreasury() external;

    function setAdminRole(address _adminAddress) external;
}