// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVesting {
    function claimed(address _beneficiary) external view returns (uint256);

    function getAvailAmt(address _beneficiary) external view returns (uint256);

    function claim() external;

    function getTotalAllocated(address _beneficiary)
        external
        view
        returns (uint256);

    function isRefundRequested(address _beneficiary) external view returns (bool);

    event RefundRequested(address user);
}