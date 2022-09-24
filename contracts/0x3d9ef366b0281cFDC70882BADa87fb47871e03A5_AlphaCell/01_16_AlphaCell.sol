// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AlphaCell is ERC721Enumerable, AccessControl {

    using Strings for uint256;
    using MerkleProof for bytes32[];
    using ECDSA for bytes32;

    // mint role preserve for future mint after public sale
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // free & open claim
    uint256 public freeClaimMaxMint = 2;
    mapping(address => uint256) public freeClaimMintedCount;

    // claim merkle root
    bytes32 public claimMerkleRoot;
    uint256 public claimPerMint = 2;
    mapping(address => bool) public claimed;

    // whitelist
    uint256 public whitelistSalePrice = 0 ether;
    uint256 public whitelistMaxMint = 2;
    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) public whitelistMintedCount;

    // public mint
    uint256 public publicSalePrice = 0.007 ether;
    uint256 public publicMaxMint = 5;
    uint256 public publicMintMaxSupply = 10000;

    // states
    bool public freeClaimMintable = false;
    bool public claimMintable = false;
    bool public whitelistMintable = false;
    bool public publicMintable = false;

    // URI
    string private _baseURIExtended;

    constructor() ERC721("ALPHA CELL", "CELL") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    // only accepts EOA
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "EOA address only");
        _;
    }

    // validating the merkle proof
    modifier onlyValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(root != "", "merkleRoot not set");
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "not existed within the list"
        );
        _;
    }

    // setup free claim for amount per claim
    function setupFreeClaimInfo(uint256 maxMintAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        freeClaimMaxMint = maxMintAmount;
    }

    // setup claim merkle root and amount per claim
    function setupClaimInfo(bytes32 merkleRoot, uint256 claimAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimMerkleRoot = merkleRoot;
        claimPerMint = claimAmount;
    }

    // setup whitelist merkle root / max mint per whitelist / price of each mint
    function setupWhitelistSaleInfo(bytes32 merkleRoot, uint256 maxMint, uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistMerkleRoot = merkleRoot;
        whitelistMaxMint = maxMint;
        whitelistSalePrice = price;
    }

    // setup public max mint per tx / price of each mint
    function setupPublicSaleInfo(uint256 maxMint, uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicMaxMint = maxMint;
        publicSalePrice = price;
    }

    // flip free claim status (on/off claim)
    function flipFreeClaimMintable() external onlyRole(DEFAULT_ADMIN_ROLE) {
        freeClaimMintable = !freeClaimMintable;
    }

    // flip claim status (on/off claim)
    function flipClaimMintable() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimMintable = !claimMintable;
    }

    // flip whitelist status (on/off whitelist)
    function flipWhitelistMintable() external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistMintable = !whitelistMintable;
    }

    // flip whitelist status (public sale)
    function flipPublicMintable() external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicMintable = !publicMintable;
    }

    function _safeMintAmount(uint256 amount) internal {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // team reserve
    function reserveMint(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _safeMintAmount(amount);
    }

    // withdraw funds
    function withdraw(address receiver) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(receiver).transfer(balance);
    }

    // set max mint
    function setPublicMintMaxSupply(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        publicMintMaxSupply = amount;
    }

    // future adopt (be called from new contract and providing the role to it)
    function adoptMint(uint256 amount) external onlyRole(MINTER_ROLE) {
        _safeMintAmount(amount);
    }

    // update uri
    function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURIExtended = baseURI_;
    }

    // free claim
    function freeClaimMint(
        uint256 amount
    ) external onlyEOA{
        require(freeClaimMintable, "free claim mint is not open yet");
        require(freeClaimMintedCount[msg.sender] + amount <= freeClaimMaxMint, "Free claim mint cap");
        require(totalSupply() + amount <= publicMintMaxSupply, "maximum mint reached");
        _safeMintAmount(amount);
        freeClaimMintedCount[msg.sender] += amount;
    }

    // claim for support
    function claimMint(
        bytes32[] calldata proof
    ) external onlyEOA onlyValidMerkleProof(proof, claimMerkleRoot) {
        require(claimMintable, "claim mint is not open yet");
        require(claimed[msg.sender] == false, "already claimed");
        require(totalSupply() + claimPerMint <= publicMintMaxSupply, "maximum mint reached");
        _safeMintAmount(claimPerMint);
        claimed[msg.sender] = true;
    }

    // whitelist mint
    function whitelistMint(
        bytes32[] calldata proof,
        uint256 amount
    ) external payable onlyEOA onlyValidMerkleProof(proof, whitelistMerkleRoot) {
        require(whitelistMintable, "Whitelist mint is not open yet");
        require(whitelistMintedCount[msg.sender] + amount <= whitelistMaxMint, "Whitelist mint cap");
        require(
            whitelistSalePrice * amount == msg.value,
            "Sent ether value is incorrect"
        );
        require(totalSupply() + amount <= publicMintMaxSupply, "maximum mint reached");
        _safeMintAmount(amount);
        whitelistMintedCount[msg.sender] += amount;
    }

    // public mint
    function publicMint(uint256 amount) external payable onlyEOA {
        require(publicMintable, "public mint is not open yet");
        require(
            publicSalePrice * amount == msg.value,
            "Sent ether value is incorrect"
        );
        require(amount <= publicMaxMint, "public mint cap per TX");
        require(totalSupply() + amount <= publicMintMaxSupply, "maximum mint reached");
        _safeMintAmount(amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();
        require(bytes(base).length != 0, "baseURI not set");
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }
}