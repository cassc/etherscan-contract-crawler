// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from  "../base/Base.sol";

contract MetadataFacet is Base {
    /// @notice Name for NFTs in this contract
    function name() external view returns (string memory) {
        return s.nftStorage.name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory) {
        return s.nftStorage.symbol;
    }

    /// @notice ContractURI containing metadata for marketplaces
    /// @return The _contractURI
    function contractURI() external view returns (string memory) {
        return s.nftStorage.contractURI;
    }

    /// @notice Used to set the baseURI for metadata
    /// @dev Se deben poner los permisos a nivel de diamante
    /// @param newBaseURI_ The base URI
    function setBaseURI(string calldata newBaseURI_) external isEmpty(newBaseURI_) {
         s.nftStorage.baseURI = newBaseURI_;
    }

    /// @notice Used to set the contractURI
    /// @dev Se deben poner los permisos a nivel de diamante
    /// @param newContractURI_ The base URI
    function setContractURI(string calldata newContractURI_) external isEmpty(newContractURI_) {
         s.nftStorage.contractURI = newContractURI_;
    }
}