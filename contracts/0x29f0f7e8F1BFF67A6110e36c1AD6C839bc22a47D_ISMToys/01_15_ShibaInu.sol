// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ISMToys is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
  
    uint256 public maxSupply = 299;
    uint256 public price = 0.14 ether;
    uint256 public maxPerTransaction = 5;
    uint256 public publicEndtime = 0;

    string internal baseTokenURI;

    mapping(address => uint256) public _whitelist;

    constructor() ERC721("Shiboshis Club X Bugatti X IsmToys", "SCBI") {}

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function mint(uint256 _numOfTokens) public payable {
        uint256 supply = totalSupply();

        require(block.timestamp <= publicEndtime, "Public Sale is not active");
        require(_numOfTokens <= maxPerTransaction, "Cannot mint above the limit");
        require(supply + _numOfTokens <= maxSupply, "Sold out!");
        require(price * _numOfTokens <= msg.value,"Ethereum amount sent is not correct");

        for (uint256 i = 0; i < _numOfTokens; i++) {
            _safeMint(msg.sender, supply  + i);
        }
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function setPublicEndtime(uint256 endtime) external onlyOwner {
        publicEndtime = endtime;
    }
  
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance should be more then zero");
        payable(address(msg.sender)).transfer(
            balance
        );
    }

    // Standard functions to be overridden in ERC721Enumerable
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }
}

// Contract developed by Allo GmbH
// [email protected]