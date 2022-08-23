pragma solidity ^0.8.0;

interface IMetadataFactory{
    struct nftMetadata {
        uint8 nftType;//0->Zombie 1->Survivor
        uint8[] traits;
        uint8 level;
        // uint nftCreationTime;
        // bool canClaim;
        // uint stakedTime;
        // uint lastClaimTime;
    }

    function createRandomMetadata(uint8 level, uint8 tokenType) external returns(nftMetadata memory);
    function createRandomZombie(uint8 level) external returns(uint8[] memory, uint8);
    function createRandomSurvivor(uint8 level) external returns(uint8[] memory, uint8);
    function constructNft(uint8 nftType, uint8[] memory traits, uint8 level) external view returns(nftMetadata memory);
    function buildMetadata(nftMetadata memory nft, bool survivor,uint id) external view returns(string memory);
    function levelUpMetadata(nftMetadata memory nft) external returns (nftMetadata memory);
}