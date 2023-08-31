// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  dmx's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 *  Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

interface IContractMetadata {

    function contractURI() external view returns (string memory);

    function setContractURI(string calldata _uri) external;

    event ContractURIUpdated(string prevURI, string newURI);
}