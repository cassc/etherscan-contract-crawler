// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DefaultOperatorFilterer} from "./filter/DefaultOperatorFilterer.sol";
import {OperatorFilterRegistry} from "./filter/OperatorFilterRegistry.sol";
import "./ERC721A.sol";

contract pals is Ownable, ERC721A, ReentrancyGuard, DefaultOperatorFilterer, OperatorFilterRegistry {
    uint256 public MAX_SUPPLY = 4444;
    uint256 public PRICE = 0;
    uint256 public maxPresale = 5;
    uint256 public maxPublicTx = 5;

    bool public _isActive = false;
    bool public _presaleActive = false;

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    mapping(address => uint8) public _preSaleListCounter;

    // merkle root
    bytes32 public preSaleRoot;

    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //set variables
    function setActive(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function presaleActive(bool isActive) external onlyOwner {
        _presaleActive = isActive;
    }

    function setMaxPresale(uint256 _maxPresale) external onlyOwner {
        maxPresale = _maxPresale;
    }

    function setMaxPublicTx(uint256 _maxPubTx) external onlyOwner {
        maxPublicTx = _maxPubTx;
    }

    function setPreSaleRoot(bytes32 _root) external onlyOwner {
        preSaleRoot = _root;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
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

    // airdrop
    function airdrop(address[] calldata _addresses)
        external
        onlyOwner
        nonReentrant
    {
        require(
            totalSupply() + _addresses.length <= MAX_SUPPLY,
            "would exceed max supply"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            _safeMint(_addresses[i], 1);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
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
        require(PRICE * quantity == msg.value, "Incorrect funds");

        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, preSaleRoot, leaf),
            "Invalid MerkleProof"
        );
        _preSaleListCounter[msg.sender] =
            _preSaleListCounter[msg.sender] +
            quantity;
        _safeMint(msg.sender, quantity);
    }

    //withdraw to owner wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
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

    // OperatorFilter
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        payable
        onlyAllowedOperator
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}