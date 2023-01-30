// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface migratingSourceFunctions {
    function getSingleStake(address _staker, uint256 index)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}