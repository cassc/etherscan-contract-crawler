// SPDX-License-Identifier: UNLICENSED
// 
// 
//  .d8888b.                                    888         888b     d888                                           .d8888b.                    d8b          888             
// d88P  Y88b                                   888         8888b   d8888                                          d88P  Y88b                   Y8P          888             
// Y88b.                                        888         88888b.d88888                                          Y88b.                                     888             
//  "Y888b.    .d88b.   .d8888b 888d888 .d88b.  888888      888Y88888P888  .d88b.  88888b.   .d88b.  888  888       "Y888b.    .d88b.   .d8888b 888  .d88b.  888888 888  888 
//     "Y88b. d8P  Y8b d88P"    888P"  d8P  Y8b 888         888 Y888P 888 d88""88b 888 "88b d8P  Y8b 888  888          "Y88b. d88""88b d88P"    888 d8P  Y8b 888    888  888 
//       "888 88888888 888      888    88888888 888         888  Y8P  888 888  888 888  888 88888888 888  888            "888 888  888 888      888 88888888 888    888  888 
// Y88b  d88P Y8b.     Y88b.    888    Y8b.     Y88b.       888   "   888 Y88..88P 888  888 Y8b.     Y88b 888      Y88b  d88P Y88..88P Y88b.    888 Y8b.     Y88b.  Y88b 888 
//  "Y8888P"   "Y8888   "Y8888P 888     "Y8888   "Y888      888       888  "Y88P"  888  888  "Y8888   "Y88888       "Y8888P"   "Y88P"   "Y8888P 888  "Y8888   "Y888  "Y88888 
//                                                                                                        888                                                            888 
//                                                                                                   Y8b d88P                                                       Y8b d88P 
//                                                                                                    "Y88P"                                                         "Y88P"  
//
// [website] https://secretmoneysociety.xyz/
// [discord] https://discord.gg/secretmoneynft
// [twitter] https://twitter.com/secretmoneynft
// 
// [we like the art]

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SecretMoneySocietyV2 is ERC721, Ownable, ReentrancyGuard, PaymentSplitter {

    using Strings for uint256;
    using MerkleProof for bytes32[];

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public currentPrice = 0.14 ether;
    uint256 public maxSupply = 5555;
    uint256 public totalSupply = 0;
    uint256 public maxWhitelistMintPerWallet = 4;
    uint256 public maxMintPerTxn = 10;

    bool public publicPaused = true;
    bool public whitelistPaused = true;
    bool public revealed = false;

    bytes32 public merkleRoot;

    address t1 = 0xE90256ec73Ec4591fFa86AC99ee03dC664F31f0F; // Community Wallet
    address t2 = 0xbbe43612b9B577d5d9cB786324880c01d5792Ebc; // Artist
    address t3 = 0xab52ddd891F3FED34632c8560b0970A97D306946; // Developer
    address t4 = 0x66021c830939f39eEf8DaB95D6dcF427F2b25658; // Marketing

    address[] addressList = [t1, t2, t3, t4];
    uint256[] shareList = [40, 40, 10, 10];

    mapping(address => uint256) public whitelistMintPerWallet;

    constructor()
    ERC721("Secret Money Society V2", "SMS")
    PaymentSplitter(addressList, shareList)  {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) public payable nonReentrant {
        require(!publicPaused, "mint: public sale not active");
        require(quantity > 0, "mint: minimum 1");
        require(quantity <= maxMintPerTxn, "mint: exceeded maximum quantity per txn");
        require(totalSupply + quantity <= maxSupply, "mint: would exceed max supply");
        require(msg.value >= currentPrice * quantity, "mint: ether sent is not correct");

        for (uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            totalSupply += 1;
        }
    }

    function mintWhitelist(
        bytes32[] calldata proof,
        uint256 quantity
    ) public payable nonReentrant {
        require(proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender))), "mint: not on whitelist");
        require(!whitelistPaused, "mint: whitelist sale not active");
        require(whitelistMintPerWallet[msg.sender] + quantity <= maxWhitelistMintPerWallet, "mint: exceeds maximum quanity per whitelist");
        require(quantity > 0, "mint: minimum 1");
        require(quantity <= maxWhitelistMintPerWallet, "mint: exceeded maximum quantity per txn for whitelist");
        require(totalSupply + quantity <= maxSupply, "mint: would exceed max supply");
        require(msg.value >= currentPrice * quantity, "mint: ether sent is not correct");

        for (uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            whitelistMintPerWallet[msg.sender] += 1;
            totalSupply += 1;
        }
    }

    function gift(
        address _wallet,
        uint256 quantity
    ) public onlyOwner {
        require(quantity > 0, "gift: minimum 1");
        require(totalSupply + quantity <= maxSupply, "gift: would exceed max supply");
        
        for(uint256 i; i < quantity; i++){
            _safeMint(_wallet, totalSupply + 1);
            totalSupply += 1;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        if (revealed) {
            return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
        } else {
            return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, "preview", baseExtension))
                : "";
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        currentPrice = _newPrice;
    }

    function setMaxMintPerTxn(uint256 _newMaxMintPerTxn) public onlyOwner {
        maxMintPerTxn = _newMaxMintPerTxn;
    }

    function setMaxMintPerWhitelist(uint256 _newMaxMintPerWhitelist) public onlyOwner {
        maxWhitelistMintPerWallet = _newMaxMintPerWhitelist;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setWhitelistPaused(bool _state) public onlyOwner {
        whitelistPaused = _state;
    }

    function setPublicPaused(bool _state) public onlyOwner {
        publicPaused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function migrateTokens(address addr) public onlyOwner {
        uint256 previousSupply = IERC20(addr).totalSupply();
        for (uint i = 1; i <= previousSupply; i++) {
            address owner = IERC721(addr).ownerOf(i);
            _safeMint(owner, i);
            totalSupply += 1;
        }
    }

}