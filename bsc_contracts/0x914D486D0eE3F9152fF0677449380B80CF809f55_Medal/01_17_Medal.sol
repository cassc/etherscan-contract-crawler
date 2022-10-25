// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-v0.8/utils/Counters.sol";
import "@openzeppelin/contracts-v0.8/utils/Strings.sol";
import "@openzeppelin/contracts-v0.8/token/ERC721/extensions/ERC721Enumerable.sol";
import "../common/Mintable.sol";

/**
 * @title Medal
 * @author Genesis Universe-TEAM
 */
contract Medal is ERC721Enumerable, Mintable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /* ========== STATE VARIABLES ========== */
    Counters.Counter private _tokenIdTracker;
    string private baseURI;
    uint16 public maxSupply;

    /* ========== CONSTRUCTOR ========== */
    constructor(address _owner, string memory _baseURI) ERC721("Genesis Universe Medal", "GUM") {
        maxSupply = 1500;
        baseURI = _baseURI;
        _transferOwnership(_owner);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function mint(address _to) public onlyMinter whenNotPaused {
        require(totalSupply() < maxSupply, "Medal: Max supply reached.");
        _tokenIdTracker.increment();
        uint256 tokenId = _tokenIdTracker.current();
        _safeMint(_to, tokenId);
        emit Mint(_to, tokenId);
    }

    function batchMint(address _to, uint256 _count) external onlyMinter whenNotPaused {
        require(_count != 0, "Medal: NFT mint count can't be zero.");
        require(totalSupply() + _count <= maxSupply, "Medal: Max supply reached.");

        for (uint256 i = 0; i < _count; i++) {
            mint(_to);
        }
        emit BatchMint(_to, _count);
    }

    /* ========== VIEW FUNCTIONS ========== */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Medal: token is not exists.");
        return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /* ========== EVENTS ========== */
    event Mint(address indexed to, uint256 indexed id);
    event BatchMint(address indexed to, uint256 count);
    event SetBaseURI(string indexed baseURI);
}