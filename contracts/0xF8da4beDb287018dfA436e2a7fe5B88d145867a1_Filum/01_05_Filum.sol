// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import './ERC721A.sol';

contract Filum is Ownable, ERC721A {
    string private _baseTokenURI;
    string private _defaultURI;

    mapping(uint256 => bool) public hasChangedURI;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => bool) private _hasMinted;
    mapping(string => bool) private _uriExists;

    uint256 public constant MAX_TOKENS = 100;
    uint256 public constant OWNER_MINT_LIMIT = 10;
    bool private _ownerHasBatchMinted = false;

    constructor(string memory name, string memory symbol, string memory baseURI, string memory defaultURI) ERC721A(name, symbol) {
        _baseTokenURI = baseURI;
        _defaultURI = defaultURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenURIs[tokenId];
    }

    function _changeTokenURI(uint256 tokenId, string memory newURI) internal {
        require(_exists(tokenId), "Token does not exist");
        require(!hasChangedURI[tokenId], "Token URI can only be changed once");

        _tokenURIs[tokenId] = newURI;
    }

    function changeTokenURI(uint256 tokenId, string memory newURI) external {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner of this token");
        require(!hasChangedURI[tokenId], "Token URI can only be changed once");
        require(!_uriExists[newURI], "This URI already exists");

        _tokenURIs[tokenId] = newURI;
        hasChangedURI[tokenId] = true;
        _uriExists[newURI] = true;
    }

    function setDefaultURI(string calldata newDefaultURI) external onlyOwner {
        _defaultURI = newDefaultURI;
    }

    function batchMintByOwner(string memory uri) external onlyOwner {
        require(!_ownerHasBatchMinted, "Owner can only batch mint once");
        require(totalSupply() + 10 <= MAX_TOKENS, "Minting would exceed maximum tokens");
        _safeMint(msg.sender, OWNER_MINT_LIMIT, "");
        _ownerHasBatchMinted = true;

        for (uint i = 0; i < OWNER_MINT_LIMIT; i++) {
            _changeTokenURI(i, uri);
        }
    }

    function mint(string memory mintURI) external {
        require(totalSupply() < MAX_TOKENS, "Maximum tokens reached");
        require(msg.sender != owner(), "Owner should use batchMintByOwner");
        require(!_hasMinted[msg.sender], "You have already minted a token");
        _hasMinted[msg.sender] = true;
        uint256 newTokenId = totalSupply();
        _safeMint(msg.sender, 1, "");
        _changeTokenURI(newTokenId, mintURI);
    }

    // New function to change the base URI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function uriExists(string memory uri) public view returns (bool) {
        return _uriExists[uri];
    }

}