// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TycoonApes is ERC721, Pausable, Ownable {

    uint[] public prices = [100 ether, 2 ether, 1 ether, 0.5 ether];
    bool[] public allowedCollections = [true, true, false, false];
    string public URI = "https://g88.gg/nft/";

    constructor() ERC721("TycoonApes", "TYCN") {}

    // Admin methods

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setURI(string memory _URI) public onlyOwner {
        URI = _URI;
    } 

    function setAllowedCollections(bool[] memory _allowedCollections) public onlyOwner {
        allowedCollections = _allowedCollections;
    }

    function setPrice(uint _collectionId, uint _price) public onlyOwner {
        prices[_collectionId] = _price;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Public methods

    function buyNft(uint256 tokenId) public whenNotPaused payable {
        require(tokenId > 0 && tokenId <= 9999, "Exceeds 9999");
        uint collectionId = _collectionIndex(tokenId);
        require(allowedCollections[collectionId], "Purchases from this collection not allowed");
        require(msg.value >= prices[collectionId], "Not enough funds sent to purchase");
        
        _safeMint(msg.sender, tokenId);
    }

    // internal methods

    function _collectionIndex(uint256 tokenId) internal pure returns(uint collectionId) {
        if(tokenId < 10){
            return 0;
        } else if(tokenId < 100){
            return 1;
        } else if(tokenId < 1000){
            return 2;
        } else {
            return 3;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

}