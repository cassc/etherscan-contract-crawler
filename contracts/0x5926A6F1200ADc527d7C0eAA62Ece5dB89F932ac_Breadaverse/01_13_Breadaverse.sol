// SPDX-License-Identifier: MIT

/***
 __          __      _______          _____  _       _ _        _
 \ \        / /     |__   __|        |  __ \(_)     (_) |      | |
  \ \  /\  / /_ _ _   _| | ___   ___ | |  | |_  __ _ _| |_ __ _| |
   \ \/  \/ / _` | | | | |/ _ \ / _ \| |  | | |/ _` | | __/ _` | |
    \  /\  / (_| | |_| | | (_) | (_) | |__| | | (_| | | || (_| | |
     \/  \/ \__,_|\__, |_|\___/ \___/|_____/|_|\__, |_|\__\__,_|_|
                   __/ |                        __/ |
                  |___/                        |___/
***/
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Breadaverse is ERC721A, Ownable {
    using MerkleProof for bytes32[];
    using Strings for uint256;

    uint16 public constant publicNfts = 6420;
    uint16 public constant reservedNfts = 480;

    uint16 private devsMinted;
    uint48 private publicMinted;

    bytes32 public merkleRoot;

    bool public preReveal = true;

    string private baseURI;
    string private preRevealBaseURI;

    bool public saleStarted = false;
    bool public publicSaleStarted = false;

    uint256 public breadPrice = 0 ether;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    function setPreRevealBaseURI(string memory _preRevealBaseUri) public onlyOwner {
        preRevealBaseURI = _preRevealBaseUri;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    function mint(
        bytes32[] memory proof,
        bytes32 leaf,
        uint8 amount
    ) public payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(msg.value == (breadPrice * amount), "The price is invalid");
        require(saleStarted == true, "The sale is paused");
        require(publicMinted + amount <= publicNfts, "Mint limit reached");

        if (publicSaleStarted == false) {
            require(keccak256(abi.encodePacked(msg.sender)) == leaf, "This leaf does not belong to the sender");
            require(proof.verify(merkleRoot, leaf), "You are not in the list");
            require(_numberMinted(msg.sender) + amount <= 5, "Address minted max amount");
        } else {
            require(_numberMinted(msg.sender) + amount <= 2, "Address minted max amount");
        }

        publicMinted += amount;

        _mint(msg.sender, amount);
    }

    //Reserved for marketing, devs, etc
    function devMint(address to, uint16 amount) public onlyOwner {
        require(devsMinted + amount <= reservedNfts, "Exceeded max supply for devs");

        devsMinted += amount;

        _mint(to, amount);
    }

    function startSale() public onlyOwner {
        saleStarted = true;
    }

    function pauseSale() public onlyOwner {
        saleStarted = false;
    }

    function togglePublicSale() public onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function setbreadPrice(uint256 price) public onlyOwner {
        breadPrice = price;
    }

    function reveal() public onlyOwner {
        preReveal = false;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (preReveal == true) return string(abi.encodePacked(preRevealBaseURI, tokenId.toString()));
        else return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}