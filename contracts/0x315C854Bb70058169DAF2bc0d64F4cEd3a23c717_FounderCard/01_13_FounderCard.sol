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
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract FounderCard is ERC721A, Ownable, PaymentSplitter, DefaultOperatorFilterer {
    using MerkleProof for bytes32[];
    using Strings for uint256;

    uint16 public reservedNFTsAmount;

    bytes32 public merkleRoot;
    bytes32 public emailMerkleRoot;

    string private baseURI;

    bool public saleStarted = false;
    bool public publicSaleStarted = false;

    uint16 public constant totalNFTs = 500;
    uint16 public constant reservedNFTS = 50;

    uint256 public nftPrice = 1.44 ether;

    address[] private payees = [0x7605DAD9EEfbd22490ba228Ad756a6256045c5FE, 0x30d6B3497e967B72013e921aAf5d5ee9915B1010];
    uint256[] private payeesShares = [9650, 350];

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

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    // Crossmint function with allowlist verification
    function mintTo(
        uint256 amount,
        bytes32[] memory proof,
        bytes32 leaf,
        address to
    ) external payable canMint(amount) {
        address crossmintEth = 0xdAb1a1854214684acE522439684a145E62505233;

        require(msg.sender == crossmintEth, "This function can be called by the Crossmint address only.");
        require(proof.verify(emailMerkleRoot, leaf), "You are not in the list");

        _mint(to, amount);
    }

    // public minting Crossmint function
    function mintTo(uint256 amount, address to) external payable canMint(amount) {
        address crossmintEth = 0xdAb1a1854214684acE522439684a145E62505233;

        require(msg.sender == crossmintEth, "This function can be called by the Crossmint address only.");
        require(publicSaleStarted == true, "The public sale is paused");

        _mint(to, amount);
    }

    // Mint function with allowlist verification and public sale
    function mint(
        bytes32[] memory proof,
        bytes32 leaf,
        uint256 amount
    ) external payable canMint(amount) isInAllowlist(proof, leaf) {
        _mint(msg.sender, amount);
    }

    function reserveNFT(address to, uint16 amount) external onlyOwner {
        require(reservedNFTsAmount + amount <= reservedNFTS, "Out of stock");

        reservedNFTsAmount += amount;

        _mint(to, amount);
    }

    function startSale() external onlyOwner {
        saleStarted = true;
    }

    function pauseSale() external onlyOwner {
        saleStarted = false;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setEmailMerkleRoot(bytes32 _root) external onlyOwner {
        emailMerkleRoot = _root;
    }

    function setNFTPrice(uint256 price) external onlyOwner {
        nftPrice = price;
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

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    modifier canMint(uint256 amount) {
        require(msg.value == (nftPrice * amount), "The price is invalid");
        require(saleStarted == true, "The sale is paused");
        require(totalSupply() - reservedNFTsAmount + amount <= totalNFTs - reservedNFTS, "Mint limit reached");
        _;
    }

    modifier isInAllowlist(bytes32[] memory proof, bytes32 leaf) {
        if (publicSaleStarted == false) {
            require(proof.verify(merkleRoot, leaf), "You are not in the list");
        }

        _;
    }
}