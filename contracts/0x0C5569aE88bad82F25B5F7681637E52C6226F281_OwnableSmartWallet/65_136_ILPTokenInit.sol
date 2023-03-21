pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

/// @dev Interface for initializing a newly deployed LP token
interface ILPTokenInit {
    function init(
        address _deployer,
        address _transferHookProcessor,
        string calldata tokenSymbol,
        string calldata tokenName
    ) external;
}