pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiUserDeposit {
    function getBalance() external view returns (uint256);
    function getExcessBalance() external view returns (uint256);
    function deposit() external payable;
    function recycleDissolvedDeposit() external payable;
    function recycleWithdrawnDeposit() external payable;
    function recycleDistributorDeposit() external payable;
    function assignDeposits() external;
    function withdrawExcessBalance(uint256 _amount) external;
    function withdrawExcessBalanceForSuperNode(uint256 _amount) external;
    function withdrawExcessBalanceForLightNode(uint256 _amount) external;
}