// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GreedIsland is ERC721A, ReentrancyGuard, Ownable {

    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 1024;
    uint256 public constant MINT_PRICE = 2.5 ether;
    string private _baseTokenURI;
    string private _defaultTokenURI;

    // constructor() ERC721A("Greed Island", "GI") {
    constructor() ERC721A("Greed Island", "GI") {
        _defaultTokenURI = "ipfs://QmUA5RqqwXmZzCU8wibfnboBF86AdfShL6fsPZgSbX9XkR";
    }

    function tokenURI(uint256 tokenId) 
        public 
        override 
        view 
        returns 
        (string memory) 
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _baseURI = baseURI();
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : _defaultTokenURI;
    }

    function mint(
        uint256 quantity
    ) 
        external 
        payable 
    {
        require(msg.value == MINT_PRICE * quantity, "Ether not match");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed alloc");
        _safeMint(msg.sender, quantity);
    }

    function invitations(
        address[] calldata players
    ) 
        external 
        onlyOwner
        nonReentrant
    {
        for (uint256 i; i < players.length; i++) {
            _safeMint(players[i], 1);
        } 
    }

    function setBaseURI(
        string calldata URI
    ) 
        external 
        onlyOwner 
    {
        _baseTokenURI = URI;
    }

    function setDefaultTokenURI(
        string calldata URI
    ) 
        external 
        onlyOwner 
    {
        _defaultTokenURI = URI;
    }

    function baseURI() 
        public 
        view 
        returns 
        (string memory) 
    {
        return _baseTokenURI;
    }

    function withdraw() 
        external 
        onlyOwner 
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}