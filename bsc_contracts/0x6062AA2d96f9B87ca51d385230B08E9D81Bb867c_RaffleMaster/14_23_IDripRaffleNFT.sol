pragma solidity ^0.8.0;

interface IDripRaffleNFT
{
    function mint(address to) external;
    function _tokenIds() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}