//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./INarratorsHutMetadata.sol";

struct MintInput {
    uint256 totalCost;
    uint256 expiresAt;
    TokenData[] tokenDataArray;
    bytes mintSignature;
}

struct TokenData {
    // Can safely use uint48 for these values since they can
    // comfortably fit within 2^48
    uint48 witchId;
    uint48 artifactId;
}

interface INarratorsHut {
    function mint(MintInput calldata mintInput) external payable;

    function getArtifactForToken(uint256 tokenId)
        external
        view
        returns (ArtifactManifestation memory);

    function getTokenIdForArtifact(
        address addr,
        uint48 artifactId,
        uint48 witchId
    ) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function setIsSaleActive(bool _status) external;

    function setIsOpenSeaConduitActive(bool _isOpenSeaConduitActive) external;

    function setMetadataContractAddress(address _metadataContractAddress)
        external;

    function setNarratorAddress(address _narratorAddress) external;

    function setBaseURI(string calldata _baseURI) external;

    function withdraw() external;

    function withdrawToken(IERC20 token) external;
}