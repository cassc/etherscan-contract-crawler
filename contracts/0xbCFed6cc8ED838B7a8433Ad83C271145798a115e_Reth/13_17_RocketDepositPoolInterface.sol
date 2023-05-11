// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface RocketDepositPoolInterface {
    function getBalance() external view returns (uint256);

    function getExcessBalance() external view returns (uint256);

    function deposit() external payable;

    function recycleDissolvedDeposit() external payable;

    function recycleExcessCollateral() external payable;

    function recycleLiquidatedStake() external payable;

    function assignDeposits() external;

    function withdrawExcessBalance(uint256 _amount) external;
}