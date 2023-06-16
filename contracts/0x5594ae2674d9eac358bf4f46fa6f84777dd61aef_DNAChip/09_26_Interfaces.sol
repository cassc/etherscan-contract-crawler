// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface RewardLike {
    function mintMany(address to, uint256 amount) external;
}

interface IDNAChip is RewardLike {
    function tokenIdToTraits(uint256 tokenId) external view returns (uint256);

    function isEvolutionPod(uint256 tokenId) external view returns (bool);

    function breedingIdToEvolutionPod(uint256 tokenId) external view returns (uint256);
}

interface IDescriptor {
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function tokenBreedingURI(uint256 _tokenId, uint256 _breedingId) external view returns (string memory);
}

interface IEvolutionTraits {
    function getDNAChipSVG(uint256 base) external view returns (string memory);

    function getEvolutionPodImageTag(uint256 base) external view returns (string memory);

    function getTraitsImageTags(uint8[8] memory traits) external view returns (string memory);

    function getMetadata(uint8[8] memory traits) external view returns (string memory);
}

interface IERC721Like {
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function transfer(address to, uint256 id) external;

    function ownerOf(uint256 id) external returns (address owner);

    function mint(address to, uint256 tokenid) external;
}