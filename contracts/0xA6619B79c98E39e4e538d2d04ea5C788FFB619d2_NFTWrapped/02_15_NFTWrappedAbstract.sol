// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IMintableBundle.sol";

abstract contract NFTWrappedAbstract is ERC721, Ownable, IMintableBundle {
    using Strings for uint256;

    uint256 public immutable PRICE;

    address public bundleContract;
    string public baseURI;

    uint256 private _tokenId = 0;

    constructor(string memory name, string memory symbol, uint256 _price, string memory _baseURI, address _bundleContract) ERC721(name, symbol) {
        bundleContract = _bundleContract;
        baseURI = _baseURI;
        PRICE = _price;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenId;
    }

    function mint() external payable {
        require(msg.value >= PRICE, "Not enough ETH");
        _tokenId++;
        _safeMint(msg.sender, _tokenId);
    }

    function mintBundle(address to) external {
        require(msg.sender == bundleContract, "Only bundle contract");
        _tokenId++;
        _safeMint(to, _tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId));

        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Only owner

    function gift(address to) external onlyOwner {
        _tokenId++;
        _safeMint(to, _tokenId);
    }

    function setBundleContract(address _bundleContract) external onlyOwner {
        bundleContract = _bundleContract;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
}