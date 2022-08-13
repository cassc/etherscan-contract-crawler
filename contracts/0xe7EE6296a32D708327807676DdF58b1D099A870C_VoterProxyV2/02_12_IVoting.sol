// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVoting {
    function vote(address[] calldata, uint256[] calldata) external;

    function getVote(uint256)
        external
        view
        returns (
            bool,
            bool,
            uint64,
            uint64,
            uint64,
            uint64,
            uint256,
            uint256,
            uint256,
            bytes memory
        );

    function vote_for_gauge_weights(address, uint256) external;
}