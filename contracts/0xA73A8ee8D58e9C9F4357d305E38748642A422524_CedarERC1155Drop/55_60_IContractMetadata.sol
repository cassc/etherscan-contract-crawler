// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ICedarMetadataV1 {
    /// @dev Contract level metadata.
    function contractURI() external view returns (string memory);

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external;

    /// @dev Emitted when contractURI is updated
    event ContractURIUpdated(address indexed updater, string uri);
}

interface IPublicMetadataV0 {
    /// @dev Contract level metadata.
    function contractURI() external view returns (string memory);
}

interface IRestrictedMetadataV0 {
    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external;
}