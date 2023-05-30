// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./ERC721A.sol";

contract Breezy is Ownable, ERC721A, ReentrancyGuard, PaymentSplitter {
    uint256 public MAX_SUPPLY = 10000;
    uint256 public PRICE = 0.34 ether;
    uint256 public PRESALE_PRICE = 0.282 ether;
    uint256 public maxPresale = 1;
    uint256 public maxPublicTx = 5; //max per tx public mint
    address public winterAddress = 0xd541da4C37e268b9eC4d7D541Df19AdCf564c6A9;
    address public winterAddress2 = 0xf175d78a30197d51475155134d20A9DC59B5AD71;
    address public winterAddress3 = 0x581952551ac905C91D760b797eAC2Bd579A07378;

    bool public _isActive = false;
    bool public _presaleActive = false;

    mapping(address => uint8) public _preSaleListCounter;

    // merkle root
    bytes32 public preSaleRoot;

    constructor(
        string memory name,
        string memory symbol,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721A(name, symbol) PaymentSplitter(payees, shares) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //set variables
    function setActive(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function setPresaleActive(bool isActive) external onlyOwner {
        _presaleActive = isActive;
    }

    function setMaxPresale(uint256 _maxPresale) external onlyOwner {
        maxPresale = _maxPresale;
    }

    function setPreSaleRoot(bytes32 _root) external onlyOwner {
        preSaleRoot = _root;
    }

    function setMaxPublicTx(uint256 quantity) external onlyOwner {
        maxPublicTx = quantity;
    }

    // Internal for marketing, devs, etc
    function internalMint(uint256 quantity, address to)
        external
        onlyOwner
        nonReentrant
    {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "would exceed max supply"
        );
        _safeMint(to, quantity);
    }

    // metadata URI
    string private _baseTokenURI;

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //withdraw to owner wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setPresalePrice(uint256 _price) external onlyOwner {
        PRESALE_PRICE = _price;
    }

    function setWinterAddress(address sender) external onlyOwner {
        winterAddress = sender;
    }

    function setWinterAddress2(address sender) external onlyOwner {
        winterAddress2 = sender;
    }

    function setWinterAddress3(address sender) external onlyOwner {
        winterAddress3 = sender;
    }

    // Presale with credit card
    function mintPreSaleCard(
        address recipient,
        uint8 quantity,
        bytes32[] calldata _merkleProof
    ) external payable callerIsUser nonReentrant {
        require(_presaleActive, "Presale is not active");
        require(
            _preSaleListCounter[recipient] + quantity <= maxPresale,
            "Exceeded max available to purchase"
        );
        require(quantity > 0, "Must mint more than 0 tokens");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Purchase would exceed max supply of Tokens"
        );
        require(PRESALE_PRICE * quantity == msg.value, "Incorrect funds");
        require(
            msg.sender == winterAddress ||
                msg.sender == winterAddress2 ||
                msg.sender == winterAddress3,
            "Not authorized"
        );
        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(recipient));
        require(
            MerkleProof.verify(_merkleProof, preSaleRoot, leaf),
            "Invalid MerkleProof"
        );
        _safeMint(recipient, quantity);
        _preSaleListCounter[recipient] =
            _preSaleListCounter[recipient] +
            quantity;
    }

    // Presale
    function mintPreSaleTokens(uint8 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(_presaleActive, "Pre mint is not active");
        require(
            _preSaleListCounter[msg.sender] + quantity <= maxPresale,
            "Exceeded max available to purchase"
        );
        require(quantity > 0, "Must mint more than 0 tokens");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Purchase would exceed max supply of Tokens"
        );
        require(PRESALE_PRICE * quantity == msg.value, "Incorrect funds");

        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, preSaleRoot, leaf),
            "Invalid MerkleProof"
        );
        _safeMint(msg.sender, quantity);
        _preSaleListCounter[msg.sender] =
            _preSaleListCounter[msg.sender] +
            quantity;
    }

    // public credit card mint
    function publicCardMint(address recipient, uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(quantity > 0, "Must mint more than 0 tokens");
        require(_isActive, "public sale has not begun yet");
        require(PRICE * quantity == msg.value, "Incorrect funds");
        require(quantity <= maxPublicTx, "exceeds max per transaction");
        require(totalSupply() + quantity <= MAX_SUPPLY, "reached max supply");
        _safeMint(recipient, quantity);
    }

    // public mint
    function publicSaleMint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(quantity > 0, "Must mint more than 0 tokens");
        require(_isActive, "public sale has not begun yet");
        require(PRICE * quantity == msg.value, "Incorrect funds");
        require(quantity <= maxPublicTx, "exceeds max per transaction");
        require(totalSupply() + quantity <= MAX_SUPPLY, "reached max supply");
        _safeMint(msg.sender, quantity);
    }
}