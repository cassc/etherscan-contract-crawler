// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IStaking {
    struct Stake {
        uint256[] tokenIds;
        uint256 timestamp;
    }

    function getStake(address _user) external view returns (Stake memory);
}