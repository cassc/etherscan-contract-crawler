// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol" ;

interface IMITNft is IERC721 {
    function mint(uint256 tokenId, address owner) external returns(bool) ;
    function batchMint(uint256 [] memory tokenIds, address owner) external returns(bool) ;
    function migration(uint256 tokenId, uint256 gene, address owner) external returns(bool) ;
    function batchMigration(uint256 [] memory tokenIds, uint256 [] memory gens, address owner) external returns(bool);
    function batchBurn(uint256[] memory tokenIds) external returns(bool) ;
    function safeBatchTransferFrom(address from, address to, uint256[] memory tokenId ) external returns (bool) ;
    function setGens(uint256 gen, uint256 tokenId) external returns(bool);
    function batchSetGens(uint256 [] memory tokenIds, uint256 [] memory genes) external returns(bool) ;
    function batchOwnerOf(uint256 [] memory tokenIds) external view returns(address [] memory) ;
    function getNftOwnerGensByIds(uint256 [] memory tokenIds) external view returns(uint256 [] memory, address [] memory);
    function burn(uint256 tokenId) external ;
}