// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract TimoolCocktailClub is ERC721URIStorage, Ownable {
    uint256 public id;
    uint256 private _maxSupply = 5000;

    constructor() ERC721("TimoolCocktailClub", "TCC"){
        id = 0;
    }

    function createArtNFT (string memory _tokenURI) external onlyOwner returns (uint256){
        require(id < _maxSupply, "maxSupply exceeded");

        uint256 tokenId = id;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        id ++;

        return tokenId;
    }

    //get Owners by id and limit
    function getOwnersbyLimit(uint256 _id, uint256 _limit) external view returns(address[] memory ownerData){
        uint256 length = _id > _limit ? _limit : (_id + 1);
        ownerData = new address[](length);

        for(uint256 i = 0; i < length; i ++){
            ownerData[i] = ownerOf(_id + i + 1 - length);
        }
        return ownerData;
    }

    //get tokenURIs by id and limit
    function getURIbyLimit(uint256 _id, uint256 _limit) external view returns (string[] memory uRIData){
        uint256 length = _id > _limit ? _limit : (_id + 1);
        uRIData = new string[](length);

         for(uint256 i = 0; i < length; i ++){
            uRIData[i] = tokenURI(_id  + i + 1 - length);
        }
        return uRIData;
    }

    function getAllOwner() external view returns(address[] memory allOwner){
        allOwner = new address[](id);
        
        for(uint256 i = 0; i < id; i ++){
            allOwner[i] = ownerOf(i);
        }
        return allOwner;
    }

    function getAllURI() external view returns(string[] memory allURI){
        allURI = new string[](id);
        
        for(uint256 i = 0; i < id; i ++){
            allURI[i] = tokenURI(i);
        }
        return allURI;
    }
}