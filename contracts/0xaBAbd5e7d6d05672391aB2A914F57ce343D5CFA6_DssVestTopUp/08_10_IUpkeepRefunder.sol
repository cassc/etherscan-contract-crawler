// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUpkeepRefunder {
    function refundUpkeep() external;

    function shouldRefundUpkeep() external view returns (bool);

    function setUpkeepId(uint256 _upkeepId) external;
}