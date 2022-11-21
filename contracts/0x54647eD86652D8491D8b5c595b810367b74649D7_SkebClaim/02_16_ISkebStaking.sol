// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

interface ISkebStaking {
    function stake(uint128 _amount) external;

    function unstake(uint256 _stakeIndex) external;

    function stakeFor(address _user, uint128 _amount) external;
}