//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRewardUtils.sol";

interface IDelegationUtils is IRewardUtils {
    event Delegated(
        address indexed user,
        address indexed delegate,
        uint256 shares,
        uint256 totalDelegatedTo
        );

    event Undelegated(
        address indexed user,
        address indexed delegate,
        uint256 shares,
        uint256 totalDelegatedTo
        );

    event UpdatedDelegation(
        address indexed user,
        address indexed delegate,
        bool delta,
        uint256 shares,
        uint256 totalDelegatedTo
        );

    function delegateVotingPower(address delegate) 
        external;

    function undelegateVotingPower()
        external;

    
}