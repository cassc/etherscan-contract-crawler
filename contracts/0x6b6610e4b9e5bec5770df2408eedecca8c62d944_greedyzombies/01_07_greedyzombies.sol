// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract greedyzombies is ERC721A, Ownable, ReentrancyGuard { 

    uint256 public _maxSupply = 2500;
    uint256 public _mintPrice = 0.003 ether;
    uint256 public _maxMintPerTx = 30;

    uint256 public _maxFreeMintPerAddr = 5;
    uint256 public _maxFreeMintSupply = 1000;

    using Strings for uint256;
    string public baseURI;
    mapping(address => uint256) private _mintedFreeAmount;

    constructor(string memory initBaseURI) ERC721A("greedyzombies", "GZ") {
        baseURI = initBaseURI;
    }

    function mint(uint256 count) external payable {
        uint256 cost = _mintPrice;
        bool isFree = ((totalSupply() + count < _maxFreeMintSupply + 1) &&
            (_mintedFreeAmount[msg.sender] + count <= _maxFreeMintPerAddr)) ||
            (msg.sender == owner());

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < _maxSupply + 1, "Sold out!");
        require(count < _maxMintPerTx + 1, "Max per TX reached.");

        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        _maxFreeMintSupply = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        _mintPrice = _newPrice;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}