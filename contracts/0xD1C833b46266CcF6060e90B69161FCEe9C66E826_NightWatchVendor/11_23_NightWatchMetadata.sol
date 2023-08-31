// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {INightWatchMetadata} from "./interfaces/INightWatchMetadata.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @title Night Watch Metadata Contract
/// @notice Separate metadata contract to support future possible on-chain image generation
/// @author @YigitDuman
contract NightWatchMetadata is INightWatchMetadata, Owned {
    /// @notice Base URI for token metadata
    string private _baseURI;

    /// @notice Constructor
    /// @param baseURI Base URI for token metadata
    constructor(string memory baseURI) Owned(msg.sender) {
        _baseURI = baseURI;
    }

    /// @notice Set base URI for token metadata
    /// @param baseURI Base URI for token metadata
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURI = baseURI;
    }

    /// @notice Get the token URI for token metadata
    /// @param tokenId Token ID
    /// @return string Token URI for token metadata
    function tokenURI(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseURI, LibString.toString(tokenId)));
    }
}