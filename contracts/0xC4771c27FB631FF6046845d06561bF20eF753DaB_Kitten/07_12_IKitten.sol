// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IKitten {
    enum Trait {
        Background,
        Body,
        Clothes,
        Ears,
        Eyes,
        Head,
        Neck,
        Special,
        Weapon
    }

    struct Kitten {
        uint8 background;
        uint8 body;
        uint8 clothes;
        uint8 ears;
        uint8 eyes;
        uint8 head;
        uint8 neck;
        uint8 special;
        uint8 weapon;
    }

    /// ERC721-like

    function getOwner(uint256 tokenId) external view returns (address);

    function getNextTokenId() external view returns (uint256);

    /// WarKittens

    function mint(uint256 amount, address to) external payable;

    function mintCommunitySale(address to, bytes32[] calldata merkleProof) external payable;

    function reserveForGifting(uint256 amount) external;

    function giftKittens(address[] calldata addresses) external;

    function getKitten(uint256 tokenId) external view returns (Kitten memory);

    function getTrait(uint256 tokenId, Trait trait) external view returns (uint8);

    function updateTrait(uint256 tokenId, Trait trait, uint8 value) external;
}