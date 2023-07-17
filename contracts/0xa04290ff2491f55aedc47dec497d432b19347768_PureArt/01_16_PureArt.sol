// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Base64.sol";
import "./IGenerator.sol";

contract PureArt is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bool maxTotalSet;
    uint256 public price;
    uint256 public maxMint;
    uint256 public maxTotal;
    bool public paused = true;
    IGenerator public generator;
    bool public generatorLocked;
    mapping (uint256 => uint256) public randomizers;

    constructor(string memory _desc, string memory _token, uint256 _price, uint256 _maxTotal, uint256 _maxMint) ERC721(_desc, _token) {
        price = _price;
        maxMint = _maxMint;
        maxTotal = _maxTotal;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        uint256 seed = randomizers[tokenId];
        if (seed == 0) return "";
        return generator.tokenURI(tokenId, seed);
    }

    function mint(uint256 amount) payable external {
        require(paused == false, 'paused');
        require(amount > 0 && amount <= maxMint, '!amount');
        require(totalSupply() + amount <= maxTotal, '!noneLeft');
        require(msg.value == amount * price, '!price');
        _sendEth(msg.value);
        for (uint256 i = 0; i < amount; i++) {
            _mintToken();
        }
    }

    function _mintToken() internal returns(uint256 tokenId) {
        _tokenIds.increment();
        tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
        randomizers[tokenId] = _getRandomValue(tokenId);
    }

    function _getRandomValue(uint256 tokenId) internal view returns(uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, tokenId)));
    }

    function _owns(address erc721, uint256 id, address _owner) internal view returns(bool) {
        return IERC721(erc721).ownerOf(id) == _owner;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function _sendEth(uint256 eth) internal {
        (bool success, ) = owner().call{value: eth}("");
        require(success, '!sendEth');
    }

    // Lock the generator. It can be replaced to protect against bugs, but should be locked at some point
    function lockGenerator() external onlyOwner {
        generatorLocked = true;
    }

    // Generator can be set in case of bugs, but should be locked at some point
    function setGenerator(address _generator) external onlyOwner {
        require(!generatorLocked, '!generatorLocked');
        require(_generator != address(0), '!generator');
        generator = IGenerator(_generator);
    }

    // Useful for dutch auction style pricing
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    // Useful if it doesn't sell out to stop minting, can only do this once
    function setMaxTotal(uint256 _maxTotal) external onlyOwner {
        require(maxTotalSet == false && _maxTotal < maxTotal, '!setMaxTotal');
        maxTotalSet = true;
        maxTotal = _maxTotal;
    }

 }