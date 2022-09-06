// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PixelBlossomCollection is ERC721Enumerable, Ownable {
    using Strings for uint;

    bool public locked = false;
    bool public active = false;

    uint public maxSupply;
    string public baseURI;
    string public ipfsHash;
    string public ipfsBaseURI;
    bool public useIpfs = false;
    address[] public artists;
    bool[] public signatures;

    modifier onlyUnlocked() {
        require(!locked, "PixelBlossomCollection: Only if unlocked");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint _maxSupply,
        string memory _baseURI,
        string memory _ipfsBaseURI,
        address[] memory _artists
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        baseURI = _baseURI;
        ipfsBaseURI = _ipfsBaseURI;
        artists = _artists;
        _setSignatures(artists.length);
    }

    function sign() external {
        for (uint i = 0; i < artists.length; i++) {
            if (artists[i] == msg.sender) {
                signatures[i] = true;
                break;
            }
        }
    }

    function _mintNFTs(address to, uint qty) internal onlyUnlocked() {
        require(active, "PixelBlossomCollection: collection must be active");
        require(maxSupply >= totalSupply() + qty, "PixelBlossomCollection: Cannot exceed max supply");

        for (uint i = 0; i < qty; i++) {
            _mint(to, totalSupply() + 1);
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUseIpfs(bool _useIpfs) external onlyOwner {
        useIpfs = _useIpfs;
    }

    function setIpfsBaseURI(string memory _ipfsBaseURI) external onlyOwner {
        ipfsBaseURI = _ipfsBaseURI;
    }

    function setActive(bool _active) external onlyOwner {
        active = _active;
    }

    function setArtists(address[] calldata _artists) external onlyOwner onlyUnlocked() {
        artists = _artists;
        _setSignatures(_artists.length);
    }

    function setIpfsHash(string memory _ipfsHash) external onlyOwner onlyUnlocked() {
        ipfsHash = _ipfsHash;
    }

    function setLocked(bool _locked) external onlyOwner onlyUnlocked() {
        locked = _locked;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

        if (useIpfs) {
            return string(abi.encodePacked(ipfsBaseURI, ipfsHash, "/", tokenId.toString()));
        }

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function _setSignatures(uint artistsLength) private {
        signatures = new bool[](artistsLength);
        for (uint i = 0; i < artistsLength; i++) {
            signatures[i] = false;
        }
    }
}