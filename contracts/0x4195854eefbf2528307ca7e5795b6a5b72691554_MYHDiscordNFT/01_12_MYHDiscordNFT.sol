// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract MYHDiscordNFT is ERC721A, Ownable {
    bool public earlyMintOpen = false;
    bool public regularMintOpen = false;
    uint256 private maxEarlyMint = 3;
    uint256 public pauseAtId = 0;

    string private uri =
        "https://gateway.pinata.cloud/ipfs/QmbDiMfGDbrFGqatFtngW3BvMyYog8rUiiRHAbhZFzsMHQ";

    uint256 public pricePerNFT;

    mapping(address => uint256) private numberMinted;
    mapping(uint256 => string) private uriByTokenId;

    constructor(uint256 _pricePerNFT)
        ERC721A("MoneyHero.club Membership Tickets", "MYHCLB")
    {
        pricePerNFT = _pricePerNFT;
    }

    //Minting controls
    function openEarlyMint(bool _isOpen) public onlyOwner {
        earlyMintOpen = _isOpen;
    }

    function openMint(bool _isOpen) public onlyOwner {
        regularMintOpen = _isOpen;
    }

    function newInfluencer(uint256 _maxMintsForInfluencer, string memory _uri)
        public
        onlyOwner
    {
        pauseAtId = currentIndex + _maxMintsForInfluencer;
        uri = _uri;
    }

    function mint(uint256 _quantity) public payable {
        require(earlyMintOpen || regularMintOpen);
        require(msg.value == pricePerNFT * _quantity, "Wrong ETH amount sent.");
        require(
            (currentIndex + _quantity) < pauseAtId + 1,
            "Reached pauseAt Id value"
        );

        if (!regularMintOpen) {
            //Only whitelisted users can mint
            require(
                _quantity < (maxEarlyMint + 1 - numberMinted[msg.sender]),
                "User attempted to mint more than max allowed"
            );
            numberMinted[msg.sender] += _quantity;
        }

        for (uint256 i = 0; i < _quantity; i++) {
            uriByTokenId[currentIndex + i] = uri;
        }

        _safeMint(msg.sender, _quantity);
    }

    //Admin edit & withdraw eth functions
    function setPricePerNFT(uint256 _pricePerNFT) public onlyOwner {
        pricePerNFT = _pricePerNFT;
    }

    function setUri(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function setMaxEarlyMint(uint256 _max) public onlyOwner {
        maxEarlyMint = _max;
    }

    function setPauseAtId(uint256 _pauseAtId) public onlyOwner {
        pauseAtId = _pauseAtId;
    }

    function setUriById(uint256 _id, string memory _uri) public onlyOwner {
        uriByTokenId[_id] = _uri;
    }

    function withdrawEth() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //Metadata URI functions
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

        return
            bytes(uriByTokenId[tokenId]).length > 0
                ? uriByTokenId[tokenId]
                : "";
    }

    function ownedTokensByAddress(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 totalTokensOwned = balanceOf(owner);
        uint256[] memory allTokenIds = new uint256[](totalTokensOwned);
        for (uint256 i = 0; i < totalTokensOwned; i++) {
            allTokenIds[i] = (tokenOfOwnerByIndex(owner, i));
        }
        return allTokenIds;
    }
}