//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintifyLitePass is ERC721, Ownable {

    uint16 nextTokenId = 1;
    string private baseURI = "https://ipfs.io/ipfs/QmbqVwJ4pyWKt6EYvbTZ1sa5gqe9u4wVMsoTF5XTMBTiYk";


    // Constructor
    constructor() ERC721("Mintify Lite Pass", "MNTFYLP") {
            
    }

    // Mint
    function airDrop(address[] memory accounts) public onlyOwner {
        for (uint i=0; i < accounts.length; i++) {
            _safeMint(accounts[i], nextTokenId);
            nextTokenId++;
        }
    }

    // Sets BaseURI
    function setBaseURI(string calldata _baseURI ) public onlyOwner {
        baseURI = _baseURI;
    }

    // Gets total supply
    function totalSupply() public view returns(uint) {
        return nextTokenId - 1;
    }

    // Withdraw Balance to Address
    function withdraw(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    // Gets token URI
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return bytes(baseURI).length > 0 ? baseURI : "";
    }

}