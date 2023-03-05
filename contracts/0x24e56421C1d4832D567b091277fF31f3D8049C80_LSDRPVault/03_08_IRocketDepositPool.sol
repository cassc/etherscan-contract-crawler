// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IRocketDepositPool {
    function getBalance() external view returns (uint256);

    function getExcessBalance() external view returns (uint256);

    function deposit() external payable;

    function recycleDissolvedDeposit() external payable;

    function recycleExcessCollateral() external payable;

    function recycleLiquidatedStake() external payable;

    function assignDeposits() external;

    function withdrawExcessBalance(uint256 _amount) external;

}