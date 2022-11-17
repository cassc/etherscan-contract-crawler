// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface Factory {
    function feeCollector() external view returns (address);

    function platformFee(address) external view returns (uint256);
}