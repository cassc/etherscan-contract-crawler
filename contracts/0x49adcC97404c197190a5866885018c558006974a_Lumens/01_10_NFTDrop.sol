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

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Lumens is ERC721A, Ownable, PaymentSplitter {
    using MerkleProof for bytes32[];
    using Strings for uint256;

    bytes32[4] public merkleRoot;

    mapping(address => uint8) public alreadyMinted;

    uint16 public reservedNFTsAmount;
    // 0 - VIP NFTs
    // 1 - Tier 1 NFTs
    // 2 - Tier 2 NFTs
    // 3 - Public Minting NFTs (and Premint)
    uint8[] public nftAmountByStage = [6, 4, 2, 6];

    uint16 private constant maxNFTSupply = 8888;
    uint16 private constant reservedNFTs = 219;

    bool public preReveal = true;
    bool public saleStarted = false;
    bool public publicSaleStarted = false;

    string private baseURI;
    string private preRevealBaseURI;

    uint256 public nftPrice = 0.04444 ether;

    //The below addresses are for example purposes only. Please modify them.
    address[] private payees = [
        0xDbD10Ff27EA8c4d8ea6795397996361862091410,
        0x38198ee928400Cd81ED4B72Aa0c550eF1c9ebE28,
        0x78F2268fEe6dd5ab3e30Ef1F040C62777b5DF42e,
        0x5dF768b522b341E5caf2CB5ef47eA3424BEb4a4D,
        0x8c540BFb73D39CcCb59A2d48907091C19F191F55,
        0x2f508BE8Ac24d694b796411B35330aaB7c40E913,
        0xa16231D4DA9d49968D2191328102F6731Ef78FCA,
        0x30d6B3497e967B72013e921aAf5d5ee9915B1010,
        0x2B11D45ea9f7d133B7b3deDd5fd884cF6385CA7B
    ];

    //The below percentages are for example purposes only. Please modify them.
    uint256[] private payeesShares = [14, 5, 4, 2, 5, 1, 1, 5, 63];

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) PaymentSplitter(payees, payeesShares) {
        reservedNFTsAmount = 0;
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
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
        uint8 amount,
        uint8 stage
    ) public payable {
        if (stage != 3) {
            require(keccak256(abi.encodePacked(msg.sender)) == leaf, "This leaf does not belong to the sender");
            require(proof.verify(merkleRoot[stage], leaf), "You are not in the list");
        } else {
            require(publicSaleStarted, "The public sale is paused");
        }

        _internalMint(msg.sender, amount, stage);
    }

    function _internalMint(
        address to,
        uint8 amount,
        uint8 stage
    ) internal {
        require(saleStarted, "The sale is paused");
        require(msg.value == nftPrice * amount, "The price is invalid");
        unchecked {
            require(totalSupply() + amount <= maxNFTSupply, "Mint limit reached");
            require(
                alreadyMinted[msg.sender] + amount <= nftAmountByStage[stage],
                "Amount requested is over max amount per wallet"
            );
            alreadyMinted[to] += amount;
        }

        _mint(msg.sender, amount);
    }

    function reserveNFT(address to, uint16 amount) public onlyOwner {
        unchecked {
            require(reservedNFTsAmount + amount <= reservedNFTs, "Out of stock");

            reservedNFTsAmount += amount;
        }

        _mint(to, amount);
    }

    function setMerkleRoot(bytes32 _root, uint8 stage) public onlyOwner {
        merkleRoot[stage] = _root;
    }

    function reveal() public onlyOwner {
        preReveal = false;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(os, "Ether transfer failed");
    }

    function withdrawPaymentSplitter() external onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            address payable wallet = payable(payees[i]);
            release(wallet);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (preReveal == true) return string(abi.encodePacked(preRevealBaseURI, tokenId.toString()));
        else return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setNFTPrice(uint256 price) public onlyOwner {
        nftPrice = price;
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
}