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

interface IDelegatedMetadataV0 {
    /// @dev Contract level metadata.
    function contractURI() external view returns (string memory);
}

interface IRestrictedMetadataV0 {
    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external;
}

interface IRestrictedMetadataV1 is IRestrictedMetadataV0 {
    /// @dev Emitted when contractURI is updated
    event ContractURIUpdated(address indexed updater, string uri);
}

interface IRestrictedMetadataV2 is IRestrictedMetadataV1 {
    /// @dev Lets a contract admin set the token name and symbol
    function setTokenNameAndSymbol(string calldata _name, string calldata _symbol) external;

    /// @dev Emitted when token name and symbol are updated
    event TokenNameAndSymbolUpdated(address indexed updater, string name, string symbol);
}