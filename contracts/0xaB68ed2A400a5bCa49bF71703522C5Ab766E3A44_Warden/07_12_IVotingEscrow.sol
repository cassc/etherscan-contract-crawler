// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/** @title Custom Interface for Curve VotingEscrow contract  */
interface IVotingEscrow {

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }
    
    function balanceOf(address _account) external view returns (uint256);

    function locked(address _account) external view returns (LockedBalance memory);

    function create_lock(uint256 _value, uint256 _unlock_time) external returns (uint256);

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function locked__end(address _addr) external view returns (uint256);

}