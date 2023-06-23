// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract degenkidz is
    ERC721A,
    PaymentSplitter,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    // Token Data
    uint256 public constant PRE_TOKEN_PRICE = 0.07 ether;
    uint256 public constant MAIN_TOKEN_PRICE = 0.08 ether;
    uint256 public constant MAX_TOKENS = 8888;
    uint256 public constant RESERVED_TOKENS = 200;
    
    uint256 public totalReserved = 0; // Track total tokens reserved

    uint256 public MAX_BATCH = 100; // ERC721A Batching
    uint256 public MAX_PRE_MINTS = 2;
    uint256 public MAX_PUB_MINTS_PER_TX = 5;

    // Contract Data
    string public _baseTokenURI;

    // Sale Switches
    bool public mainSaleActive = false;
    bool public preSaleActive = false;

    // White List Token Counters
    mapping(address => uint256) public _preSaleList;

    // Merkle Roots
    bytes32 public preSaleRoot;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address[] memory payees,
        uint256[] memory shares,
        bytes32 preSaleRoot_
    ) ERC721A(name, symbol, MAX_BATCH, MAX_TOKENS) PaymentSplitter(payees, shares) {
        setBaseURI(baseURI);
        preSaleRoot = preSaleRoot_;
    }

    /* Reserves */
    function reserveTokens(address to, uint256 numberOfTokens)
        public
        onlyOwner
    {
        require(
            totalSupply() + numberOfTokens <= MAX_TOKENS,
            "This would exceed max supply of Tokens"
        );
        require(
            totalReserved + numberOfTokens <= RESERVED_TOKENS,
            "This would exceed max reservation of Tokens"
        );

        _safeMint(to, numberOfTokens);

        // update totalReserved
        totalReserved = totalReserved + numberOfTokens;
    }

    /* Setters */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPreSaleRoot(bytes32 _preSaleRoot) public onlyOwner {
        preSaleRoot = _preSaleRoot;
    }

    /* Getters */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* Sale Switches */
    function flipPreSaleState() public onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function flipMainSaleState() public onlyOwner {
        mainSaleActive = !mainSaleActive;
    }

    /* Pre Sale */
    function mintPreSaleTokens(
        uint256 numberOfTokens,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant callerIsUser {
        require(preSaleActive, "Pre mint is not active");
        require(
            _preSaleList[msg.sender] + numberOfTokens <= MAX_PRE_MINTS,
            "Exceeded max available to purchase"
        );
        require(numberOfTokens > 0, "Must mint more than 0 tokens");
        require(
            totalSupply() + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );
        require(
            PRE_TOKEN_PRICE * numberOfTokens == msg.value,
            "Ether value sent is not correct"
        );

        // check proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, preSaleRoot, leaf),
            "Invalid MerkleProof"
        );

        // update presale counter
        _preSaleList[msg.sender] = _preSaleList[msg.sender] + numberOfTokens;

        _safeMint(msg.sender, numberOfTokens);
    }

    function numPreSaleMinted(address addr) external view returns (uint256) {
        return _preSaleList[addr];
    }

    /* Main Sale */
    function mintTokens(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(mainSaleActive, "Sale must be active to mint token");
        require(
            numberOfTokens <= MAX_PUB_MINTS_PER_TX,
            "Can only mint max purchase of tokens at a time"
        );
        require(numberOfTokens > 0, "Must mint more than 0 tokens");
        require(
            totalSupply() + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );
        require(
            MAIN_TOKEN_PRICE * numberOfTokens == msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, numberOfTokens);
    }
}