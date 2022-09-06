pragma solidity ^0.8.9;

interface IdaMo {
    function mint(address to, uint256 tokenId) external ;
    function mintNFT(address to,uint8 genera) external returns(uint256);
    function existsTokenId(uint256 tokenId)   external view returns (bool) ;
    function tokenDetail(uint256 tokenId)   external view returns (uint8,uint8,string memory) ;
    function getId() external view returns(uint256);
}