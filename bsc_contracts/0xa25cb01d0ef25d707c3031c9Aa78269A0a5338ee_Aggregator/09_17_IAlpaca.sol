// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IAlpaca {
    function sharesTotal() external view returns (uint256);

    function pendingReward(address) external view returns (uint256);
}