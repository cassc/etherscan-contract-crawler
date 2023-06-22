// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IERC20Snapshot {

    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);

    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);

}