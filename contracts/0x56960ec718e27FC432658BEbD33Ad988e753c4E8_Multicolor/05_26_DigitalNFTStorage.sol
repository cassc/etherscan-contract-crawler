// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../DigitalNFTAdvanced.sol";

/// @notice Developed by DigitalNFT.it (https://digitalnft.it/)
abstract contract DigitalNFTStorage is DigitalNFTAdvanced {
    
    // ============================== Fields ============================== //

    mapping(uint256 => string) internal _uris;

    // ============================ Functions ============================ //

    // ======================= //
    // === Admin Functions === //
    // ======================= //

    function setUri(uint256 tokenID, string calldata newUri) external onlyOwner {
        _uris[tokenID] = newUri;
    }

    function setUriBatch(uint256[] calldata tokenIDs, string[] calldata newUris) public onlyOwner {
        DigitalNFTUtilities._lengthCheck(tokenIDs, newUris);
        for (uint256 i = 0; i < tokenIDs.length; i++) _uris[tokenIDs[i]] = newUris[i];
    }
}