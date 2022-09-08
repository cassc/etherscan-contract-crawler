// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//             ____
//      _,-ddd888888bbb-._
//    d88888888888888888888b
//  d888888888888888888888888b      $$$$$$\   $$$$$$\   $$$$$$\
// 6888888888888888888888888889    $$  __$$\ $$  __$$\ $$  __$$\
// 68888b8""8q8888888p8""8d88889   $$ /  \__|$$ /  \__|$$ /  \__|
// `d8887     p88888q     4888b'   $$ |      $$ |      \$$$$$$\
//  `d8887    p88888q    4888b'    $$ |      $$ |       \____$$\
//    `d887   p88888q   488b'      $$ |  $$\ $$ |  $$\ $$\   $$ |
//      `d8bod8888888dob8b'        \$$$$$$  |\$$$$$$  |\$$$$$$  |
//        `d88888888888d'           \______/  \______/  \______/
//          `d8888888b' hjw
//            `d8888b' `97
//              `bd'

contract CCSNFTPublic is Ownable {
    NFTContract _nftContract;

    constructor(address initNftContract) {
        setNftContract(initNftContract);
    }

    function setNftContract(address contractAddress) public onlyOwner {
        _nftContract = NFTContract(contractAddress);
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "ZERO_BALANCE");
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        require(msg.value >= .05 ether, "INSUFFICIENT_FUNDS");
        _nftContract.publicMint{value: msg.value}(msg.sender);
    }
}

interface NFTContract {
    function _publicSupply() external returns (uint256);

    function getPublicMintedCount() external returns (uint256);

    function publicMint(address recipient) external payable;
}