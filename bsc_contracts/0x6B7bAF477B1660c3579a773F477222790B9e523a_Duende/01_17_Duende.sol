// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./interfaces/Utils.sol";

contract Duende is ERC721, Ownable, ERC721Enumerable, ERC721Burnable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public constant maxSupply = 999;

    string public baseURI;
    string public baseExtension = ".json";

    bool public revealed;
    string public notRevealedUri;

    Counters.Counter private _tokenIdCounter;

    event DuendeMinted(address indexed player, uint256 indexed tokenId);
    mapping(address => bool) operationsAddresses;

    modifier onlyOperators() {
        require(operationsAddresses[msg.sender] == true);
        _;
    }

    constructor(string memory _notRevealedUri) ERC721("Duende", "DUENDE") {
        operationsAddresses[msg.sender] = true;
        notRevealedUri = _notRevealedUri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
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
    
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function reveal(bool _revealed, string memory _newBaseURI) public onlyOwner {
        revealed = _revealed;
        baseURI = _newBaseURI;
    }

    function addOperationsAddress(address userAddress) public onlyOwner {
        require(userAddress != address(0) && !operationsAddresses[userAddress]);
        operationsAddresses[userAddress] = true;
    }

    function removeOperationsAddress(address userAddress) public onlyOwner {
        require(userAddress != address(0) && operationsAddresses[userAddress]);
        operationsAddresses[userAddress] = false;
    }

    function safeMintSingle(address player) external onlyOperators returns(uint256) {
        require(totalSupply() + 1 < maxSupply,"max supply reached");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(player, tokenId);
        emit DuendeMinted(player, tokenId);
        return tokenId;
    }

    function safeMint(address player,uint256 quantity) external onlyOperators {
        require(totalSupply() + quantity < maxSupply,"max supply reached");
        for(uint256 i=0; i<quantity; i++){
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(player, tokenId);
            emit DuendeMinted(player, tokenId);
        }
    }

    function getDuendeOfAddress(address player)
        public
        view
        returns (uint256[] memory)
    {
        uint256 currentBalance = balanceOf(player);
        uint256[] memory tokens = new uint256[](currentBalance);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = tokenOfOwnerByIndex(player, i);
        }
        return (tokens);
    }
}