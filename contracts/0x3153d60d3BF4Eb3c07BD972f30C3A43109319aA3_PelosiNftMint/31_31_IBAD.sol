// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBox721 is IERC721 {
    function cardIdMap(uint) external view returns(uint cardId);
    function tokenURI(uint256 tokenId_) external view returns(string memory);
    function mint(address player_, uint cardId_) external returns(uint256);
    function mintMulti(address player_, uint cardId_, uint amount_) external returns(uint256[] memory tokenIds);
    function burn(uint tokenId_) external returns (bool);
    function burnMulti(uint[] calldata tokenIds_) external returns (bool);
}


interface IBAD is IERC721 {
    function cardIdMap(uint) external view returns(uint cardId);
    function cardInfoes(uint) external returns(uint cardId, string memory name, uint currentAmount, uint maxAmount, string memory _tokenURI);
    function tokenURI(uint256 tokenId_) external view returns(string memory);
    function mint(address player_, uint cardId_) external returns(uint256);
    function mintWithId (address player_, uint cardId_, uint tokenId_) external returns (bool);
    function mintMulti(address player_, uint cardId_, uint amount_) external returns(uint256[] memory tokenIds);
    function burn(uint tokenId_) external returns (bool);
    function burnMulti(uint[] calldata tokenIds_) external returns (bool);
}