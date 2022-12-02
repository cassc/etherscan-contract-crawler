// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IXENProxying {
    function callClaimRank(uint256 term) external;

    function callClaimMintReward(address to) external;
}