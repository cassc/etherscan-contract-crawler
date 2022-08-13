// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "hardhat/console.sol";

contract MKNFT is ERC721URIStorage, ERC2981, Ownable  {
    address contractAddress;
    mapping (uint256 => bytes32) mintPasswords;
    string myContractURI = "https://firebasestorage.googleapis.com/v0/b/cadence-5403d.appspot.com/o/contract%2Fcontract.json?alt=media&token=c6464166-39ab-46df-87a3-7d15eb4b9835";

    constructor(address marketplaceAddress) ERC721("Monkey King", "MONKEYKING") {
        contractAddress = marketplaceAddress;
        setRoyaltyInfo(owner(), 1000); //1000 basis points = 10%
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFee) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFee); //Fee in basis points
    }

    function setPasswordHash(uint256 tokenId, bytes32 _hash) public onlyOwner {
        mintPasswords[tokenId] = _hash;
    }

    function checkPassword(uint256 tokenId, string memory _password) public view returns (bool){
        return (keccak256(abi.encodePacked(_password)) == mintPasswords[tokenId]);
    } 

    function createToken(uint256 tokenId, string memory _password, string memory tokenURI) public returns (uint) {

        require(checkPassword(tokenId, _password), "incorrect password");

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        setApprovalForAll(contractAddress, true);
        return tokenId;
    }

    function burn(uint256 tokenId) public onlyOwner{
        _burn(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return myContractURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner{
        myContractURI = _contractURI;
    }

     function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}