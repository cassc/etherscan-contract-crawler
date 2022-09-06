//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CryptoBears is ERC721A, Ownable {
    string public baseURI = "https://nftservices.s3.amazonaws.com/bulies/";
    bool public isPublicMintEnabled;
    uint256 public mintPrice;
    uint256 public maxSupply;

    constructor() ERC721A("CryptoBears", "CROBEARS") {
        mintPrice = 0.05 ether;
        maxSupply = 8888;
        isPublicMintEnabled = true;
    }

    function enablePublicMint() external onlyOwner {
        isPublicMintEnabled = true;
    }

    function disablePublicMint() external onlyOwner {
        isPublicMintEnabled = false;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function mint(uint256 quantity) external payable {
        require(isPublicMintEnabled, "minting is not enabled");
        require(quantity > 0, "quantity must be greater than 0");
        require(totalSupply() + quantity <= maxSupply, "sold out");
        require(quantity * mintPrice == msg.value, "ether value sent is not correct");

        _safeMint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    } 

    function withdrawTo(address to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "exceed balance");
        payable(to).transfer(amount);
    } 

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory prefix = super.tokenURI(tokenId);
        return bytes(prefix).length != 0 ? string(abi.encodePacked(prefix, ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}