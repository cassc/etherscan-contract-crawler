// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface I721{
    function mint(address player,uint ID) external;
    function cardIdMap(uint times) external view returns(uint);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function checkCardLeft(uint cardId) external view returns(uint);
    function burn(uint tokenId_) external returns (bool);
}