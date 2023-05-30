// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PortalDucks is ERC721, Ownable, ERC721Burnable {
    event SendThroughPortal(address from, uint tokenId, uint256[3] collectionIds);

    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    uint256 private _maxSupply = 3001;

    string public _provenanceHash;
    string public _baseURL;

    // Contracts variables
    // OG
    IERC721 private og;
    IERC721 private hell;
    IERC721 private secondGen;

    // Burner address
    address private _burnerAddress = 0x000000000000000000000000000000000000dEaD;

    // portal duck id => [og id, hell id, second id]
    mapping(uint256 => uint256[3]) private _portalToCollectionDucks;

    mapping(uint256 => bool) private _used2GenIds;

    bool private _isPortalActive = false;


    constructor(address ogAddress, address hellAddress, address secondGenAddress) ERC721("Nonconformist Upside Ducks", "NUD") {
        og = IERC721(ogAddress);
        hell = IERC721(hellAddress);
        secondGen = IERC721(secondGenAddress);
    }

    function sendThroughPortal(uint256 ogId, uint256 hellId, uint256 secondId) public {
        require(_isPortalActive, "Portal is not active.");
        require(tokenIds.current() < _maxSupply, "Can not mint more than max supply.");

        require(og.ownerOf(ogId) == msg.sender, "You must own the requested OG token.");
        require(hell.ownerOf(hellId) == msg.sender, "You must own the requested Hell token.");
        require(secondGen.ownerOf(secondId) == msg.sender, "You must own the requested 2Gen token.");

        // Check that the 2 gen duck wasn't used
        require(!_used2GenIds[secondId], "2Gen Duck was already used");

        // Burn Tokens
        og.safeTransferFrom(msg.sender, _burnerAddress, ogId);
        hell.safeTransferFrom(msg.sender, _burnerAddress, hellId);

        // Mark the 2 Gen as used
        _used2GenIds[secondId] = true;

        // Mint Duck
        tokenIds.increment();
        _safeMint(msg.sender, tokenIds.current());


        _portalToCollectionDucks[tokenIds.current()] = [ogId, hellId, secondId];
        emit SendThroughPortal(msg.sender, tokenIds.current(), [ogId, hellId, secondId]);
    }

    function mint(address to) public onlyOwner {
        tokenIds.increment();
        _safeMint(to, tokenIds.current());
    }

    function flipPortalState() public onlyOwner {
        _isPortalActive = !_isPortalActive;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        _maxSupply = newMaxSupply;
    }

    function setBurnerAddress(address newBurnerAddress) public onlyOwner {
        _burnerAddress = newBurnerAddress;
    }

    function setProvenanceHash(string memory newProvenanceHash) public onlyOwner {
        _provenanceHash = newProvenanceHash;
    }

    function setBaseURL(string memory newBaseURI) public onlyOwner {
        _baseURL = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function totalSupply() public view returns (uint256) {
        return tokenIds.current();
    }

    function burnerAddress() public view returns (address) {
        return _burnerAddress;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function portalToCollectionDucks(uint256 tokenId) public view returns (uint256[3] memory) {
        return _portalToCollectionDucks[tokenId];
    }

    function used2GenIds(uint256 secondGenTokenId) public view returns (bool) {
        return _used2GenIds[secondGenTokenId];
    }

    function isPortalActive() public view returns (bool) {
        return _isPortalActive;
    }

    function setUsed2Gen(uint256[] memory secondGenTokenIds) onlyOwner public {
        for(uint256 i = 0; i<secondGenTokenIds.length; i++) {
            _used2GenIds[secondGenTokenIds[i]] = true;
        }
    }

    function removeUsed2Gen(uint256[] memory secondGenTokenIds) onlyOwner public {
        for(uint256 i = 0; i<secondGenTokenIds.length; i++) {
        _used2GenIds[secondGenTokenIds[i]] = false;
        }
    }
}