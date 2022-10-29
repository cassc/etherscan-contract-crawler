// SPDX-License-Identifier: UnLicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CyberpunkPi is Ownable, ERC721Enumerable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string private baseTokenURI;
    uint256 TOTAL_TOKEN = 11415;
    uint256 start = 20000;
    Counters.Counter private _tokenIdTracker;

    mapping(address => bool) public miners;
    mapping(address => uint256) public currentIndex;
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    modifier tokenSupplyLimit(uint256 i) {
        require(totalSupply() + i <= TOTAL_TOKEN, "Token supply exceeded");
        _;
    }

    modifier onlyMiners() {
        require(miners[msg.sender] || msg.sender == owner(), "Permission denied");
        _;
    }

    function addMiner(address user) external onlyOwner {
        require(user != address(0), "Is zero address");
        miners[user] = true;
    }

    function removeMinder(address user) external onlyOwner{
        require(user != address(0), "Is zero address");
        miners[user] = false;
    }

    function mint(address to) public onlyMiners whenNotPaused tokenSupplyLimit(1) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _tokenIdTracker.increment();
        uint256 tokenId = _tokenIdTracker.current();
        tokenId = tokenId + start;
        _mint(to, tokenId);
    }
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721: token transfer while paused");
    }
}