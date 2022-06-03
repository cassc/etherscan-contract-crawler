// SPDX-License-Identifier: MIT

/// @title Interface for JBProjectHandles

pragma solidity ^0.8.0;

struct ENSName {
    string name;
    string subdomain;
}

interface IJBProjectHandles {
    event SetEnsName(uint256 indexed projectId, string indexed ensName);

    function setEnsNameFor(
        uint256 projectId,
        string calldata name,
        string calldata subdomain
    ) external;

    function ensNameOf(uint256 projectId)
        external
        view
        returns (ENSName memory ensName);

    function handleOf(uint256 projectId) external view returns (string memory);
}