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
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPaymentSplitter.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Valfrelandia is ERC721Enumerable, Ownable {
    using MerkleProof for bytes32[];
    using Strings for uint256;

    mapping(address => uint8) public alreadyMinted;
    uint8 public constant maxPerWallet = 3;
    uint8 public constant maxPerTransaction = 3;

    uint16 public reservedNFTsId;
    uint16 public nftId;

    bytes32 public merkleRoot;

    bool public preReveal = true;

    string private baseURI;
    string private preRevealBaseURI;

    bool public saleStarted = false;
    bool public publicSaleStarted = false;

    uint16 public constant totalNFTs = 10000;

    uint256 public nftPrice = 123000000000000000;

    address public paymentSplitter;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        nftId = 1; // item 1-9500
        reservedNFTsId = 9500; // item 9501-10000
    }

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
    ) public payable returns (uint256) {
        require(
            amount <= maxPerTransaction,
            string(
                abi.encodePacked(
                    "Cannot mint more than ",
                    Strings.toString(maxPerTransaction),
                    " in a single transaction"
                )
            )
        );
        require(msg.value == (nftPrice * amount), "The price is invalid");
        require(saleStarted == true, "The sale is paused");
        require(nftId + amount <= 9500, "Mint limit reached");
        require(alreadyMinted[msg.sender] <= maxPerWallet, "Address minted max amount");
        require(alreadyMinted[msg.sender] + amount <= maxPerWallet, "Amount requested is over max amount per wallet");

        if (publicSaleStarted == false) {
            require(keccak256(abi.encodePacked(msg.sender)) == leaf, "This leaf does not belong to the sender");
            require(proof.verify(merkleRoot, leaf), "You are not in the list");
        }

        alreadyMinted[msg.sender] += amount;

        for (uint8 i = 0; i < amount; i++) _safeMint(msg.sender, nftId++);

        return nftId;
    }

    function reserveNFT(address to, uint16 amount) public onlyOwner {
        require(reservedNFTsId + amount <= totalNFTs, "Out of stock");

        for (uint16 i = 0; i < amount; i++) {
            _safeMint(to, reservedNFTsId++);
        }
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

    function setNFTPrice(uint256 price) public onlyOwner {
        nftPrice = price;
    }

    function setPaymentSplitterAddress(address _address) public onlyOwner {
        paymentSplitter = _address;
    }

    function reveal() public onlyOwner {
        preReveal = false;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToSplitter(string memory agreementName) public onlyOwner {
        IPaymentSplitter(paymentSplitter).deposit{value: address(this).balance}(agreementName);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (preReveal == true) return string(abi.encodePacked(preRevealBaseURI, tokenId.toString()));
        else return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}