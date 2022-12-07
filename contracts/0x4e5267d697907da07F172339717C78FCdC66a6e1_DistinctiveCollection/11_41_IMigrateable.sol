// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMigrateable {
    struct ValidateInfo {
        // nodeSignature : Value signed by node with finalhash
        bytes nodeSignature;
        // userSignature : Value signed by user(from) with finalhash
        bytes userSignature;
        // finalHash : Hash value of information about migrate
        bytes32 finalHash;
    }

    struct SignerInfo {
        // nodeAddress : Address of the node
        address nodeAddress;
        // userAddress : Address of the user
        address userAddress;
    }

    struct TokenData {
        string IPFSHash;
        string baseURI;
        uint256 policy;
    }

    function migrateFrom(
        ValidateInfo[] memory validateInfo,
        SignerInfo memory signerInfo,
        uint256[] memory tokenIdArrayFrom,
        address to,
        uint256 salt,
        uint256 expiredAt
    ) external returns (TokenData[] memory original);
}