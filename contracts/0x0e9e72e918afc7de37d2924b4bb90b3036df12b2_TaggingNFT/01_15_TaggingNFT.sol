// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TaggingNFT is ERC721, Ownable, ReentrancyGuard {
    enum SaleStatus {
        PAUSED,
        OG_SALE,
        WHITELIST_SALE,
        PUBLIC_SALE 
    }

    using MerkleProof for bytes32[];
    using Counters for Counters.Counter;

    SaleStatus public saleStatus = SaleStatus.PAUSED;
    Counters.Counter private _tokenIdCounter;

    bool public revealed;
    string private preRevealURI;
    string private postRevealBaseURI;
    
    // OG & WHITELIST MAX MINT PER WALLET
    uint256 public constant MAX_MINTPER_WALLET = 2;
    // PUBLIC MAX MINT PER WALLET
    uint256 public constant MAX_PUBLIC_MINTPER_WALLET = 5;

    // TEAM RESERVE + OG + WHITELIST = MAX_TAGGING
    uint256 public constant MAX_TAGGING = 1000;   
    uint256 public constant TEAM_RESERVE_PERCENTAGE = 100; 
    uint256 public constant OG_TAGGING = 60;
    uint256 public constant WHITELIST_TAGGING = 840;
    
    uint256 public constant OG_PRICE_TAGGING = 0.005 ether;
    uint256 public constant WHITELIST_PRICE_TAGGING = 0.01 ether;
    uint256 public constant PUBLIC_PRICE_TAGGING = 0.015 ether;

    bytes32 public OG_MERKLE_ROOT;
    bytes32 public WHITELIST_MERKLE_ROOT;

    mapping(uint256 => bool) public claimed;
    mapping(address => uint256) public mintedCounts;

    event Minted(address indexed to, uint256 indexed tokenId, uint256 price);
    event TaggingTransfer(uint256 indexed tokenId,address indexed from,address indexed to);

    constructor(string memory _preRevealURI) ERC721("TaggingNFT", "TAGGING") {
        preRevealURI = _preRevealURI;
        for (uint256 i = 0; i < TEAM_RESERVE_PERCENTAGE; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            claimed[tokenId] = true;
            _safeMint(owner(), tokenId);
        }
    }

    function verifyOgMerkleProof(
        bytes32[] calldata _proof,
        bytes32 _leaf
    ) public view returns (bool) {
        return _proof.verify(OG_MERKLE_ROOT, _leaf);
    }

    function verifyWhitelistMerkleProof(
        bytes32[] calldata _proof,
        bytes32 _leaf
    ) public view returns (bool) {
        return _proof.verify(WHITELIST_MERKLE_ROOT, _leaf);
    }

    function ogMintNFT(bytes32[] calldata _merkleProof) external payable nonReentrant {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(saleStatus == SaleStatus.OG_SALE,"Sale is not open");
        require(saleStatus != SaleStatus.PAUSED, "Sale is paused");
        require(mintedCounts[msg.sender] < MAX_MINTPER_WALLET, "Exceeded maximum mint limit");
        require(msg.value == OG_PRICE_TAGGING, "Incorrect ether amount");
        require(!claimed[tokenId], "NFT has been claimed");
        require(MerkleProof.verify(
                _merkleProof,
                OG_MERKLE_ROOT,
                keccak256(abi.encodePacked(msg.sender))
            ),"Minter is not on OG list");
        require(tokenId <= TEAM_RESERVE_PERCENTAGE + OG_TAGGING,"Max supply reached");

        claimed[tokenId] = true;
        _safeMint(msg.sender, tokenId);
        mintedCounts[msg.sender]++;
        emit Minted(msg.sender, tokenId,OG_PRICE_TAGGING);
    }

    function whitelistMintNFT(bytes32[] calldata _merkleProof) external payable nonReentrant {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(saleStatus == SaleStatus.WHITELIST_SALE,"Sale is not open");
        require(saleStatus != SaleStatus.PAUSED, "Sale is paused");
        require(mintedCounts[msg.sender] < MAX_MINTPER_WALLET, "Exceeded maximum mint limit");
        require(msg.value == WHITELIST_PRICE_TAGGING, "Incorrect ether amount");
        require(!claimed[tokenId], "NFT has been claimed");
        require(
            MerkleProof.verify(
                _merkleProof,
                WHITELIST_MERKLE_ROOT,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "MINTER IS NOT ON TAGGING LIST"
        );
        require(tokenId <= TEAM_RESERVE_PERCENTAGE + OG_TAGGING + WHITELIST_TAGGING,"Max supply reached");
        require(tokenId <= MAX_TAGGING,"Max supply reached");
        claimed[tokenId] = true;
        _safeMint(msg.sender, tokenId);
        mintedCounts[msg.sender]++;
        emit Minted(msg.sender, tokenId,WHITELIST_PRICE_TAGGING);
    }

    function publicMint() external payable nonReentrant {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(saleStatus != SaleStatus.PAUSED, "Sale is paused");
        require(saleStatus == SaleStatus.PUBLIC_SALE,"Sale is not open");
        require(mintedCounts[msg.sender] < MAX_PUBLIC_MINTPER_WALLET, "Exceeded maximum mint limit");
        require(msg.value == PUBLIC_PRICE_TAGGING , "Incorrect ether amount");
        require(!claimed[tokenId], "NFT has been claimed");
        require(tokenId <= MAX_TAGGING,"Max supply reached");

        claimed[tokenId] = true;
        _safeMint(msg.sender, tokenId);
        mintedCounts[msg.sender]++;
        emit Minted(msg.sender, tokenId,PUBLIC_PRICE_TAGGING);
    }

    // Sale Settings
    function setSaleStatus(SaleStatus _status) external onlyOwner {
        saleStatus = _status;
    }

    // Reveal
    function startReveal(string memory _newURI) external onlyOwner {
        require(!revealed, "ALREADY REVEALED");
        revealed = true;
        postRevealBaseURI = _newURI;
    }

    function setPreRevealURI(string memory _URI) external onlyOwner {
        preRevealURI = _URI;
    }

    function getPreRevealURI() public view returns (string memory) {
        return preRevealURI;
    }

    function setPostRevealBaseURI(string memory _URI) external onlyOwner {
        postRevealBaseURI = _URI;
    }

    function getPostRevealBaseURI() public view returns (string memory) {
        return postRevealBaseURI;
    }

    function setOGMerkleRoots(bytes32 _OG_MERKLE_ROOT) external onlyOwner {
        OG_MERKLE_ROOT = _OG_MERKLE_ROOT;
    }

    function setWhiteListMerkleRoots(bytes32 _WHITELIST_MERKLE_ROOT) external onlyOwner {
        WHITELIST_MERKLE_ROOT = _WHITELIST_MERKLE_ROOT;
    }

    function _transfer(address _from,address _to,uint256 _tokenId) internal virtual override {
        super._transfer(_from, _to, _tokenId);
        emit TaggingTransfer(_tokenId, _from, _to);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        if (!revealed) return preRevealURI;
        return string(abi.encodePacked(postRevealBaseURI, Strings.toString(_tokenId)));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw failed");
    }
}