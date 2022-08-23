pragma solidity ^0.8.0;

interface IMetadata{

    function addMetadata(uint8 level,uint8 tokenType,uint tokenID) external;
    function createRandomZombie(uint8 level) external returns(uint8[] memory traits);
    function createRandomSurvivor(uint8 level) external returns(uint8[] memory traits);
    function getTokenURI(uint tokenId) external view returns (string memory);
    function changeNft(uint tokenID, uint8 nftType, uint8 level) external;
    function getToken(uint256 _tokenId) external view returns(uint8, uint8);
}