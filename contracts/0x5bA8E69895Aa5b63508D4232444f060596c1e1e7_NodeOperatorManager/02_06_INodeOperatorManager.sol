// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface INodeOperatorManager {
    struct KeyData {
        uint64 totalKeys;
        uint64 keysUsed;
        bytes ipfsHash;
    }

    function getUserTotalKeys(
        address _user
    ) external view returns (uint64 totalKeys);

    function getNumKeysRemaining(
        address _user
    ) external view returns (uint64 numKeysRemaining);

    function isWhitelisted(
        address _user
    ) external view returns (bool whitelisted);

    function registerNodeOperator(
        bytes32[] calldata _merkleProof,
        bytes memory ipfsHash,
        uint64 totalKeys
    ) external;

    function fetchNextKeyIndex(address _user) external returns (uint64);
}