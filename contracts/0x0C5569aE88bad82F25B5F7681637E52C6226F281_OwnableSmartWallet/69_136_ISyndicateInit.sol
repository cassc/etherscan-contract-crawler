pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

/// @dev Interface for initializing a newly deployed Syndicate
interface ISyndicateInit {
    function initialize(
        address _contractOwner,
        uint256 _priorityStakingEndBlock,
        address[] memory _priorityStakers,
        bytes[] memory _blsPubKeysForSyndicateKnots
    ) external;
}