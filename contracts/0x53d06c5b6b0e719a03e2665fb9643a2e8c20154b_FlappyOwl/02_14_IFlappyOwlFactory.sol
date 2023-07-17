// SPDX-License-Identifier: MIT

/*********************************
*                ///             *
*              (o,O)             *
*          ///( :~)\\\           *
*            ~"~"~               *
**********************************
*   Flappy Owl #420        * #69 *
**********************************
*   BUY NOW               * \_/" *
**********************************/

/*
* ** author  : nftadict.eth   
* ** package : @contracts/utils/IFlappyOwlFactory.sol
*/

pragma solidity ^0.8.17;

interface IFlappyOwlFactory {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}