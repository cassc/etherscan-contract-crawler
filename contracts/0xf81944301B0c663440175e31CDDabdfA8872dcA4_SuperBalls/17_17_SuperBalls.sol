// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
                            
     )))           ,,,      
    (o o)         (o o)     
ooO--(_)--Ooo-ooO--(_)--Ooo-

**/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract SuperBalls is ERC721, IERC2981, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public MAX_SUPPLY = 29;

    // ======== Royalties =========
    address public royaltyAddress;
    uint256 public royaltyPercent;

    constructor() ERC721("SuperBalls", "SUPERBALLS") {
        royaltyAddress = owner();
        royaltyPercent = 5;
    }

    function mintNFT(address recipient, string memory uri) public onlyOwner returns (uint256){
        require(totalSupply() < MAX_SUPPLY, "Can't mint more.");
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, uri);

        return newItemId;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
        return super.tokenURI(tokenId);
    }

    // ======== Royalties =========
    function setRoyaltyReceiver(address royaltyReceiver) public onlyOwner {
        royaltyAddress = royaltyReceiver;
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage) public onlyOwner {
        royaltyPercent = royaltyPercentage;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Non-existent token");
        return (royaltyAddress, salePrice * royaltyPercent / 100);
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165, ERC721Enumerable) returns (bool){
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // ======== Withdraw =========
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance is 0");
        payable(owner()).transfer(address(this).balance);
    }
}