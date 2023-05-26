// contracts/KuddleKoalas.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract KuddleKoalas is ERC721, ERC721URIStorage, Pausable, Ownable, ERC721Burnable, ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _reservedIdCounter;

    string _baseTokenURI = "https://api.kuddlekoalas.com/koala/";
    uint256 private _reserved = 100;

    uint256 public price = 30000000000000000; // 0.03 ETH
    bool public publicSaleActive = false;
    bool public presaleActive = false;

    bytes32 immutable public root;

    constructor(bytes32 merkleroot) ERC721("Kuddle Koalas", "KDDLE") {
        root = merkleroot;
    }

    function purchase(uint256 num) public payable whenNotPaused nonReentrant { 
        require( publicSaleActive,                      "Public Sale Not Yet Active");
        require( num < 8,                               "You can purchase a maximum of 7 Koalas per transactions");
        require( msg.value == price * num,              "Ether sent is not correct" );

        uint256 _supply = totalSupply();
        require( _supply + num < 7500 - _reserved,      "Exceeds maximum supply" );

        uint256 _reservedSupply = reservedSupply();
        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, _supply - _reservedSupply + _reserved + i + 1);
            _tokenIdCounter.increment();
        }
    }

    function mintPresale(bytes32[] calldata proof, uint256 num) public payable whenNotPaused nonReentrant {
        require(presaleActive,                          "Presale not yet active");
        require( num < 8,                               "You can purchase a maximum of 7 Koalas per transactions");
        require(verify(proof,root),                     "Address not whitelisted for Presale");
        require( msg.value == price * num,             "Ether sent is not correct" );

        uint256 _supply = totalSupply();
        require( _supply + num < 7500 - _reserved,      "Exceeds maximum supply" );

        uint256 _reservedSupply = reservedSupply();
        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, _supply - _reservedSupply + _reserved + i + 1);
            _tokenIdCounter.increment();
        }
    }


    function mintReserved(uint256 num) public onlyOwner {
        uint256 _reservedSupply = reservedSupply();
        require(_reservedSupply + num < _reserved,      "Exceeds maximum reserved supply");

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, _reservedSupply + i + 1);
            _tokenIdCounter.increment();
            _reservedIdCounter.increment();
        }
    }

    function reservedSupply() public view returns (uint256) {
        return _reservedIdCounter.current();
    }

    function verify(bytes32[] memory _proof, bytes32 _root) public view returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));

        return MerkleProof.verify(_proof, _root, _leaf);
    }

    function updatePrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function updateBaseURI(string memory newbaseURI) public onlyOwner {
        _baseTokenURI = newbaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function activatePresale() public onlyOwner {
        presaleActive = true;
    }

    function deactivatePresale() public onlyOwner  {
        presaleActive = false;
    }

    function activatePublicSale() public onlyOwner {
        publicSaleActive = true;
    }

    function deactivatePublicSale() public onlyOwner {
        publicSaleActive = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721,ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}