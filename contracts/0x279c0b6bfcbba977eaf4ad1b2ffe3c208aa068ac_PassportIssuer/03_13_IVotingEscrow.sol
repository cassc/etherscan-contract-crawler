// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IVotingEscrow {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function locked(address) external view returns (LockedBalance memory);

    function balanceOf(address) external view returns (uint256);
}