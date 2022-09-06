// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DarkTaverns is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_MINTS = 10;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MINT_PRICE = 0.05 ether;
    bytes32 public merkleRoot;
    string public baseUri;
    uint256 public privateMintSaleTime;
    uint256 public publicMintSaleTime;

    constructor(
        string memory _baseUri,
        uint256 _privateMintSaleTime,
        uint256 _publicMintSaleTime
    ) ERC721A("DarkTaverns", "DTK") {
        baseUri = _baseUri;
        privateMintSaleTime = _privateMintSaleTime;
        publicMintSaleTime = _publicMintSaleTime;
    }

    /* ========== MINT FUNCTIONS ========== */

    function privateMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        mintCompliance(quantity)
        nonReentrant
    {
        require(
            block.timestamp >= privateMintSaleTime &&
                block.timestamp < publicMintSaleTime,
            "DTK: Private mint not live"
        );
        require(
            isValidMerkleProof(msg.sender, merkleProof),
            "DTK: Invalid merkle proof"
        );
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity)
        external
        payable
        mintCompliance(quantity)
        nonReentrant
    {
        require(
            block.timestamp >= publicMintSaleTime,
            "DTK: Public mint not live"
        );
        _safeMint(msg.sender, quantity);
    }

    /* ========== VIEWS ========== */

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function isValidMerkleProof(address owner, bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(owner))
            );
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "DTK: Transfer failed");
    }

    /* ========== MODIFIERS ========== */

    modifier mintCompliance(uint256 quantity) {
        require(
            quantity > 0 && quantity <= MAX_MINTS,
            "DTK: Quantity not within range"
        );
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINTS,
            "DTK: Reached max mint"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "DTK: Reached max supply"
        );
        require(msg.value >= MINT_PRICE * quantity, "DTK: Insufficient funds");
        _;
    }
}