// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract degenkidzv2 is
    ERC721A,
    Ownable,
    ReentrancyGuard
{

    // Token Data
    uint256 public constant RESERVED_TOKENS = 600; // 385 airdropped + 215 reserved

    uint256 public totalReserved; // Track total tokens reserved

    uint256 public MAX_TOKENS = 5555;
    uint256 public MAX_PRE_MINTS = 2;
    uint256 public MAX_PUB_MINTS_PER_TX = 2;

    // Contract Data
    string public _baseTokenURI;

    // Sale Switches
    bool public mainSaleActive = false;
    bool public preSaleActive = false;

    // White List Token Counter
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
        bytes32 preSaleRoot_
    ) ERC721A(name, symbol) {
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

    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        MAX_TOKENS = maxTokens;
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

    /* Main Sale */
    function mintTokens(uint256 numberOfTokens)
        external
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

        _safeMint(msg.sender, numberOfTokens);
    }
}