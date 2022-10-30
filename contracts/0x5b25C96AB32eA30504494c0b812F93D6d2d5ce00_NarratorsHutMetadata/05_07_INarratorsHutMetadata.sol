//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

struct CraftArtifactData {
    uint256 id;
    string name;
    string description;
    string[] attunements;
}

struct Artifact {
    bool mintable;
    string name;
    string description;
    string[] attunements;
}

struct ArtifactManifestation {
    string name;
    string description;
    uint256 witchId;
    uint256 artifactId;
    AttunementManifestation[] attunements;
}

struct AttunementManifestation {
    string name;
    int256 value;
}

interface INarratorsHutMetadata {
    function getArtifactForToken(
        uint256 artifactId,
        uint256 tokenId,
        uint256 witchId
    ) external view returns (ArtifactManifestation memory);

    function canMintArtifact(uint256 artifactId) external view returns (bool);

    function craftArtifact(CraftArtifactData calldata data) external;

    function getArtifact(uint256 artifactId)
        external
        view
        returns (Artifact memory);

    function lockArtifacts(uint256[] calldata artifactIds) external;
}