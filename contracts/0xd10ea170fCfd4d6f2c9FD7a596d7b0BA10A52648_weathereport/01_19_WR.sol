// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract weathereport is
    ERC721Enumerable,
    PaymentSplitter,
    Ownable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using Strings for uint256;

    // Token Data
    uint256 public constant TOKEN_PRICE = 0.15 ether;
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant RESERVED_TOKENS = 550;
    uint256 public totalReserved = 0; // Track total tokens reserved

    uint256 public MAX_MINTS;

    // White List Token Data
    uint256 public MAX_PRE_MINTS;

    // Contract Data
    string public PROVENANCE;
    string public _contractURI;
    string public _baseTokenURI;

    // Sale Switches
    bool public mainSaleActive = false;
    bool public preSaleActive = false;

    // White List Token Counters
    mapping(address => uint256) public _preSaleList;

    // Merkle Roots
    bytes32 public preSaleRoot;

    // Metadata
    bool public metadataSwitch = false;
    IERC721Metadata public metadataSource;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI_,
        string memory baseURI,
        uint256 maxMints,
        uint256 maxPreMints,
        address[] memory payees,
        uint256[] memory shares,
        bytes32 preSaleRoot_
    ) ERC721(name, symbol) PaymentSplitter(payees, shares) {
        setContractURI(contractURI_);
        setBaseURI(baseURI);
        preSaleRoot = preSaleRoot_;
        MAX_MINTS = maxMints;
        MAX_PRE_MINTS = maxPreMints;
    }

    /* Reserves */
    function reserveTokens(address to, uint256 numberOfTokens)
        public
        onlyOwner
    {
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "This would exceed max supply of Tokens"
        );
        require(
            totalReserved.add(numberOfTokens) <= RESERVED_TOKENS,
            "This would exceed max reservation of Tokens"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, totalSupply());
        }

        // update totalReserved
        totalReserved = totalReserved.add(numberOfTokens);
    }

    /* Setters */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function setMaxMints(uint256 maxMints_) public onlyOwner {
        MAX_MINTS = maxMints_;
    }

    function setMaxPreMints(uint256 maxPreMints_) public onlyOwner {
        MAX_PRE_MINTS = maxPreMints_;
    }

    function setPreSaleRoot(bytes32 _preSaleRoot) public onlyOwner {
        preSaleRoot = _preSaleRoot;
    }

    /* Getters */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
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
    ) external payable nonReentrant {
        require(preSaleActive, "Pre mint is not active");
        require(
            _preSaleList[msg.sender].add(numberOfTokens) <= MAX_PRE_MINTS,
            "Exceeded max available to purchase"
        );
        require(numberOfTokens > 0, "Must mint more than 0 tokens");
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );
        require(
            TOKEN_PRICE.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        // check proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, preSaleRoot, leaf),
            "Invalid MerkleProof"
        );

        // update presale counter
        _preSaleList[msg.sender] = _preSaleList[msg.sender].add(numberOfTokens);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function numPreSaleMinted(address addr) external view returns (uint256) {
        return _preSaleList[addr];
    }

    /* Main Sale */
    function mintTokens(uint256 numberOfTokens)
        public
        payable
        nonReentrant
        callerIsUser
    {
        require(mainSaleActive, "Sale must be active to mint token");
        require(
            numberOfTokens <= MAX_MINTS,
            "Can only mint max purchase of tokens at a time"
        );
        require(numberOfTokens > 0, "Must mint more than 0 tokens");
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );
        require(
            TOKEN_PRICE.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    /* Metadata */
    function flipMetadataSwitch() public onlyOwner {
        metadataSwitch = !metadataSwitch;
    }

    function setMetadataSource(address _address) public onlyOwner {
        metadataSource = IERC721Metadata(_address);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        // extensible metadata by delegating to external metadata contract
        if (metadataSwitch) {
            return metadataSource.tokenURI(tokenId);
        } else {
            return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
        }
    }
}