// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";
import { Utilities } from "./libraries/Utilities.sol";
import { MetadataRenderAdminCheck } from "./MetadataRenderAdminCheck.sol";

contract OpepenMetadataLink is IMetadataRenderer, MetadataRenderAdminCheck {
    /// @notice The Opepen Edition address
    address public edition = 0x6339e5E072086621540D0362C4e3Cea0d643E114;

    string private _contractURI;
    string private _baseURI;

    constructor (string memory contractURI_, string memory baseURI) {
        _contractURI = contractURI_;
        _baseURI = baseURI;
    }

    /// @notice Contract URI information getter
    /// @return contract uri (if set)
    function contractURI() external view override returns (string memory) {
        return _contractURI;
    }

    /// @notice Token URI information getter
    /// @param tokenId to get uri for
    /// @return contract uri (if set)
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, '/', Utilities.uint2str(tokenId), '/metadata.json'));
    }

    /// @notice Set the contract URI
    /// @param newContractURI the new contract URI to set
    function setContractURI(string memory newContractURI) external requireSenderAdmin(edition) {
        _contractURI = newContractURI;
    }

    /// @notice Set the token metadata base URI
    /// @param newBaseURI the new base URI to set
    function setBaseURI(string memory newBaseURI) external requireSenderAdmin(edition) {
        _baseURI = newBaseURI;
    }

    /// @dev An event we emit when updating the metadata version
    event MetadataUpdate(string metadataHash);

    /// @dev A hook to call from the opepen edition contract to initialize a metadata update
    function pingMetadataUpdate(string memory metadataHash) external {
        require(msg.sender == edition, "Only the opepen edition can ping for an update.");

        // Success
        emit MetadataUpdate(metadataHash);
    }

    /// @dev We don't need to do anything in here, as we don't hold this data onchain.
    /// @param data data to init with
    function initializeWithData(bytes memory data) external {
        // ...
    }
}