// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IStargateLPStaking {
    function poolInfo(uint256 _poolIndex)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );
}