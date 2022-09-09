// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICedarMetadataV0 {
    /// @dev Contract level metadata.
    function contractURI() external view returns (string memory);

     /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external;
}