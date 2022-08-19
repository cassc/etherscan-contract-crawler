// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
* Implementation of the OpenSea Contract-level Metadata
* https://docs.opensea.io/docs/contract-level-metadata
*/
abstract contract ContractMetadata {
    
    string private _contractMetadataUri;

    function contractURI() public view returns (string memory) {
        return _contractMetadataUri;
    }

    function _setContractMetadataUri(string memory contractMetadataUri) internal {
      _contractMetadataUri = contractMetadataUri;
    }
}