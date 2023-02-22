// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetadataServer {
    struct Inscription {
        bytes32 hash;
        string height;
        string difficulty;
        string confirmations;
        string time;
        string nTx;
        string nonce;
        string version;
    }

    struct ContractInfo {
        string title;
        string description;
        string contractURI;
    }

    function addInscription(uint256 _blockNumber, Inscription memory _inscription) external;
    function serveMetadata(uint256 _tokenId) external view returns (string memory);
}