// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CoE is  ERC721, Ownable {
    uint256 public constant MAX_NFT_SUPPLY = 2073;
    uint256 public constant MAX_FREE_SUPPLY = 2073;

    uint256 public nftCount = 0;
    bool public saleIsActive = false;
    string private _baseUri;
    mapping(address => bool) public hasMinted;

    constructor() ERC721("CoExistAI", "CoE"){
        _baseUri="ipfs://QmUSN1GPC2iXfq3SjXSXQEukjgDyMjRmc1WcocpRL7CckV/";
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner
    {
        _baseUri = _baseTokenURI;
    }

    function _baseURI() internal view  virtual override(ERC721) returns (string memory) {
        return _baseUri;
    }

    function mintFreeNFT() public {
        require(saleIsActive, "Sale is not active");
        require(nftCount < MAX_FREE_SUPPLY, "Exceeds maximum free NFT supply");
        require(!hasMinted[msg.sender], "You have already minted a free NFT");

        uint256 tokenId = nftCount + 1;
        _safeMint(msg.sender, tokenId);

        nftCount++;
        hasMinted[msg.sender] = true;
    }

    function startSale() public onlyOwner {
        saleIsActive = true;
    }

    function pauseSale() public onlyOwner {
        saleIsActive = false;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}