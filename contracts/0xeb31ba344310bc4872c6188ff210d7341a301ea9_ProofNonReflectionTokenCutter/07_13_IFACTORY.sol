// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IFACTORY {
    function proofRevenueAddress() external view returns (address);

    function proofRewardPoolAddress() external view returns (address);
}