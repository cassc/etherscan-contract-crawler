// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IMiniProxySweet {

    function sweetClaimRank(uint _term) external;

    function sweetClaimRewardTo(address _to) external;
}