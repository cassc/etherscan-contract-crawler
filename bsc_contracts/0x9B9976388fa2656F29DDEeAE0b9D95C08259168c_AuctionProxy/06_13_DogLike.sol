// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface DogLike {
    function bark(
        bytes32 ilk,
        address urn,
        address kpr
    ) external returns (uint256 id);
}