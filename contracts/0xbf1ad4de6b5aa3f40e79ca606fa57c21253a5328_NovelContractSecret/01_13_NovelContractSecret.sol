// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "Strings.sol";

contract NovelContractSecret is ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public _isSaleActive = true;
    bool public _revealed = true;

    // Constants
    uint256 public constant MAX_SUPPLY = 2022;
    uint256 public mintPrice = 0.000000000001 ether;
    uint256 public maxBalance = 2022;
    uint256 public maxMint = 2022;
    string pdfPassword;
    string baseURI;
    string public _contractURI;

    string public baseExtension = ".json";


    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory initBaseURI, string memory tokenName, string memory tokenSymbol, string memory myContractURI)
        ERC721(tokenName, tokenSymbol)
    {
        baseURI = initBaseURI;
        _contractURI = myContractURI;
    }

    function mintPDF(uint256 tokenQuantity) public payable {
        require(
            msg.sender == owner(),
            "You are not the contract owner"
        );
        require(
            totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        require(
            balanceOf(msg.sender) + tokenQuantity <= maxBalance,
            "Sale would exceed max balance"
        );
        require(
            tokenQuantity * mintPrice <= msg.value,
            "Not enough ether sent"
        );
        require(tokenQuantity <= maxMint, "Can only mint 1 tokens at a time");

        _mintPDF(tokenQuantity);
        
    }

    function _mintPDF(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();

            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
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


        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //only owner
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

}