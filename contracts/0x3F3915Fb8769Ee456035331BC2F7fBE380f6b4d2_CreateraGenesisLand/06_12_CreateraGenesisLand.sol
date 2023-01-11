// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./ERC721A.sol";
import "./WhitelistMerkle.sol";
import "./DefaultOperatorFilterer.sol";

//  _____   _____    _____       ___   _____   _____   _____        ___
// /  ___| |  _  \  | ____|     /   | |_   _| | ____| |  _  \      /   |
// | |     | |_| |  | |__      / /| |   | |   | |__   | |_| |     / /| |
// | |     |  _  /  |  __|    / / | |   | |   |  __|  |  _  /    / / | |
// | |___  | | \ \  | |___   / /  | |   | |   | |___  | | \ \   / /  | |
// \_____| |_|  \_\ |_____| /_/   |_|   |_|   |_____| |_|  \_\ /_/   |_|

contract CreateraGenesisLand is ERC721A, WhitelistMerkle, Pausable, ReentrancyGuard, DefaultOperatorFilterer {

    uint256 public constant MAX_MINT_PER_ADDRESS = 1;
    uint256 public constant MAX_SUPPLY = 2500;
    uint256 public constant RESERVE_MAX_SUPPLY = 600;
    uint256 public constant PREMIUM_WHITELIST_MAX_SUPPLY = 1400;

    struct TimeConfig {
        uint256 premiumSaleStartTime;
        uint256 standardSaleStartTime;
        uint256 standardSaleEndTime;
    }

    TimeConfig public timeConfig;

    uint256 public mintedDevSupply;
    uint256 public mintedPremiumSupply;
    uint256 public mintedStandardSupply;

    string public baseURI;

    mapping(address => bool) public premiumMinted;
    mapping(address => bool) public standardMinted;

    /* @notice constructor for the Createra Genesis Land contract.
       @dev sets the baseUrl and merklRoots.
       @param initBaseURI the base url of the NFT
       @param _premiumWhitelistMerkleRoot the root of the premium whitelist merkle tree
       @param _standardWhitelistMerkleRoot the root of the standard whitelist merkle tree
       */
    constructor(string memory initBaseURI, bytes32 _premiumWhitelistMerkleRoot, bytes32 _standardWhitelistMerkleRoot)
    ERC721A("CreateraGenesisLand", "CGL")
    WhitelistMerkle(_premiumWhitelistMerkleRoot, _standardWhitelistMerkleRoot)
    {
        baseURI = initBaseURI;
    }

    /* Pausable */

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /* Time Control */

    function setPremiumSaleStartTime(uint32 timestamp) external onlyOwner {
        timeConfig.premiumSaleStartTime = timestamp;
    }

    function setStandardSaleStartTime(uint32 timestamp) external onlyOwner {
        timeConfig.standardSaleStartTime = timestamp;
    }

    function setStandardSaleEndTime(uint32 timestamp) external onlyOwner {
        timeConfig.standardSaleEndTime = timestamp;
    }

    /* ETH Withdraw */

    function withdrawETH() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /* Minting */

    // @notice For marketing etc.
    function reserveMint(uint256 quantity) external onlyOwner {
        require(
            mintedDevSupply + quantity <= RESERVE_MAX_SUPPLY,
            "too many already minted before reserve mint"
        );
        mintedDevSupply += quantity;
        _safeMint(msg.sender, quantity);
    }

    /* @notice Safely mints NFTs from premium whitelist.
       @dev free mint
       */
    function premiumWhitelistMint(bytes32[] calldata _merkleProof) external whenNotPaused {
        uint256 _premiumSaleStartTime = uint256(timeConfig.premiumSaleStartTime);
        uint256 _standardSaleStartTime = uint256(timeConfig.standardSaleStartTime);
        require(
            _premiumSaleStartTime != 0 && _standardSaleStartTime != 0 && block.timestamp >= _premiumSaleStartTime && block.timestamp < _standardSaleStartTime,
            "not in the premium sale time"
        );
        require(MerkleProof.verify(_merkleProof, premiumWhitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Invalid MerkleProof"
        );
        require(!premiumMinted[msg.sender], "not eligible for premium whitelist mint");
        require(
            mintedPremiumSupply + MAX_MINT_PER_ADDRESS <= PREMIUM_WHITELIST_MAX_SUPPLY,
            "not enough remaining reserved for premium sale to support desired mint amount"
        );
        mintedPremiumSupply += 1;
        premiumMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    /* @notice Safely mints NFTs from standard whitelist.
       @dev free mint
       */
    function standardWhitelistMint(bytes32[] calldata _merkleProof) external whenNotPaused callerIsUser {
        uint256 _standardSaleStartTime = uint256(timeConfig.standardSaleStartTime);
        uint256 _standardSaleEndTime = uint256(timeConfig.standardSaleEndTime);
        require(
            _standardSaleStartTime != 0 && _standardSaleEndTime != 0 && block.timestamp >= _standardSaleStartTime && block.timestamp < _standardSaleEndTime,
            "not in the standard sale time"
        );
        require(MerkleProof.verify(_merkleProof, standardWhitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Invalid MerkleProof"
        );
        require(!standardMinted[msg.sender], "not eligible for standard whitelist mint");
        require(
            mintedStandardSupply + mintedPremiumSupply + mintedDevSupply < MAX_SUPPLY,
            "not enough remaining reserved for standard sale to support desired mint amount"
        );
        mintedStandardSupply += 1;
        standardMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    /* @notice Safely mints NFTs from standard whitelist.
       @dev Only used for the team to mint the remaining lands after the standard sale phase
       */
    function teamMint(uint256 quantity) external onlyOwner {
        uint256 _standardSaleEndTime = uint256(timeConfig.standardSaleEndTime);
        require(
            _standardSaleEndTime != 0 && block.timestamp > _standardSaleEndTime,
            "not in the team mint time"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "too many already minted before team mint"
        );
        _safeMint(msg.sender, quantity);
    }

    /* metadata */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
    }

    /* Operator filtering */

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /* Modifiers */

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}