// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.19;

import "../../libraries/VeBalanceLib.sol";

interface IPVoteController {
    struct UserPoolData {
        uint64 weight;
        VeBalance vote;
    }

    struct UserData {
        uint64 totalVotedWeight;
        mapping(address => UserPoolData) voteForPools;
    }

    function getUserData(
        address user,
        address[] calldata pools
    )
        external
        view
        returns (uint64 totalVotedWeight, UserPoolData[] memory voteForPools);

    function getUserPoolVote(
        address user,
        address pool
    ) external view returns (UserPoolData memory);

    function getAllActivePools() external view returns (address[] memory);

    function vote(address[] calldata pools, uint64[] calldata weights) external;

    function broadcastResults(uint64 chainId) external payable;
}