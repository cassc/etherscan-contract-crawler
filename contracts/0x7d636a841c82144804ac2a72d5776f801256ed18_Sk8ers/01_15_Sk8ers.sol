// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Sk8ers is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_SK8ERS = 8888; // 8888
    uint256 public constant MINT_LIMIT = 20;
    uint256 public constant RESERVES = 100;
    uint256 private _saleTime = 1641834000; // 1641834000 (Monday 10 January 2022 17:00:00 GMT)
    uint256 private _presaleDuration = 86400; // 86400 (24 hrs)
    uint256 private _price = 80000000000000000; // 0.08 eth
    uint256 private _presalePrice = 60000000000000000; // 0.06 eth
    string public baseTokenURI;

    mapping(address => bool) private _presaleAddresses;

    constructor(string memory baseURI) ERC721("Sk8ers", "SK8ER") {
        setBaseURI(baseURI);
    }

    modifier presaleIsOpen() {
        require(block.timestamp >= _saleTime - _presaleDuration, "The Sk8ers presale has not yet started");
        require(block.timestamp < _saleTime, "Sk8ers sale has already started");
        _;
    }

    modifier saleIsOpen() {
        require(block.timestamp >= _saleTime, "Sk8ers sale is not open yet");
        _;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseTokenURI = newBaseURI;
    }

    function contractURI() public pure returns (string memory) {
        return "https://sk8ers.io/api/contract";
    }

    function setSaleTime(uint256 newTime) public onlyOwner {
        _saleTime = newTime;
    }

    function getSaleTime() public view returns (uint256) {
        return _saleTime;
    }

    function getPresaleDuration() public view returns (uint256) {
        return _presaleDuration;
    }
    
    function addPresaleAddresses(address[] memory newPresaleAddresses) public onlyOwner {
       for(uint256 i = 0; i < newPresaleAddresses.length; i++) {
            _presaleAddresses[newPresaleAddresses[i]] = true;
        }
    }

    function isPresaleAddress(address _address) public view returns (bool) {
        return _presaleAddresses[_address] == true;
    }

    function presaleMint(address _to, uint256 _count) public payable presaleIsOpen {
        uint256 total = totalSupply();
        require(isPresaleAddress(_to), "Invalid address");
        require(total + _count <= MAX_SK8ERS, "Max limit");
        require(_count <= MINT_LIMIT, "Exceeds Mint Limit");
        require(msg.value >= _presalePrice.mul(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintSk8er(_to);
        }

        payable(owner()).transfer(msg.value);
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = totalSupply();
        require(total + _count <= MAX_SK8ERS, "Max limit");
        require(_count <= MINT_LIMIT, "Exceeds Mint Limit");
        require(msg.value >= _price.mul(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintSk8er(_to);
        }

        payable(owner()).transfer(msg.value);
    }

    function reserve(uint256 _count) public onlyOwner {
        uint256 total = totalSupply();
        require(block.timestamp < _saleTime - _presaleDuration, "Presale has already started");
        require(total + _count <= RESERVES, "Reserves limit reached");

        for (uint256 i = 0; i < _count; i++) {
            _mintSk8er(msg.sender);
        }
    }

    function _mintSk8er(address _to) private {
        uint256 id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensIds = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensIds;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}