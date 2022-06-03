// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVotingEscrowMigrator {
    function migrate(
        address account,
        int128 amount,
        int128 discount,
        uint256 duration,
        uint256 end
    ) external;

    function unlockTime(address _addr) external view returns (uint256);
}