//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IMiharaNFT.sol";

contract MiharaNFTCosmos is IMiharaNFT, ERC721, Ownable, ReentrancyGuard {

    using Strings for uint256;

    uint256 public constant PRICE = 3 ether;
    address payable public constant RECIPIENT = payable(0x63A11DB3fd35dA4081a4A7667E15aE8804085a32);


    uint256 private _remainingFree = 10;
    bool private _isOnSale;
    uint256 private _nextTokenId = 1;

    constructor() ERC721("Mihara NFT Cosmos", "MIHARA") {}

    //******************************
    // No transfer
    //******************************

    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal pure override {
        require(from == address(0) || from == RECIPIENT, "No transfer");
    }

    //******************************
    // view functions
    //******************************

    function remainingFree() external view override returns (uint256) {
        return _remainingFree;
    }

    function isOnSale() external view override returns (bool) {
        return _isOnSale;
    }

    function nextTokenId() external override view returns (uint256) {
        return _nextTokenId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(bytes(abi.encodePacked('{"name":"Mihara NFT Cosmos #',  Strings.toString(tokenId),'","description": "The world\'s No. 1 garden and landscape designer Kazuyuki Ishihara aims to make Mihara-cho, his hometown, the most sacred place in the world full of flowers, greenery and smiles, and to make it a paradise.\\n\\nWe will create a town and garden that the world wants to visit, and pass on the message of love and peace from Miharacho to the world, to our children and grandchildren.","image": "https://arweave.net/Dmi8RJupNQjwxw38sJDDMlME-ZFxQD9QbWbhE0zM9fQ","attributes": [{"trait_type": "License","value": "Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)"}]}')))
            )
        );
    }

    //******************************
    // public functions
    //******************************

    function buy() external override nonReentrant payable {
        require(_isOnSale, "Not on sale");
        require(msg.value == PRICE, "Invalid value");
        uint256 tokenId = _nextTokenId;
        _nextTokenId ++;
        _safeMint(_msgSender(), tokenId);
    }

    //******************************
    // admin functions
    //******************************


    function mintFree(address to) external override onlyOwner {
        require(_remainingFree > 0, "No Free Mihara NFT is left");
        uint256 tokenId = _nextTokenId;
        _nextTokenId ++;
        _remainingFree --;
        _safeMint(to, tokenId);
    }

     function updateSaleStatus(bool __isOnSale) external override onlyOwner {
        _isOnSale = __isOnSale;
    }

    function withdrawETH() external override onlyOwner {
        Address.sendValue(RECIPIENT, address(this).balance);
    }

}