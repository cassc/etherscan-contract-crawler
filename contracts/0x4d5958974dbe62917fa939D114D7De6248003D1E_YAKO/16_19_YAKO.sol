// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract YAKO is 
    ERC721,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    
    uint256 public constant MAX_SUPPLY = 3600;
    uint256 public constant OWNER_ALLOTMENT = 200;
    uint256 public totalSupply;
    bytes32 public merkleRoot;
    string public baseURI;
    string public constant EXTENSION = ".json";
    mapping (address => bool) public whitelistClaimed;
    mapping (address => bool) public publicClaimed;
    bool public isWhitelistMintActive;
    bool public isPublicMintActive;
    bool public isMetadataFrozen;

    constructor(string memory _unrevealedURI) ERC721("3600YAKO", "YAKO") {
        baseURI = _unrevealedURI;
    }

    function setWhitelistMintActive(bool _isWhitelistMintActive) external onlyOwner {
        require(merkleRoot != 0, "YAKO: MerkleRoot is not set");
        isWhitelistMintActive = _isWhitelistMintActive;
    }

    function setPublicMintActive(bool _isPublicMintActive) external onlyOwner {
        isPublicMintActive = _isPublicMintActive;
    }

    function setRoyalty(address _royaltyAddress, uint96 _royaltyFee) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _royaltyFee);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(!isMetadataFrozen, "YAKO: Already frozen"); 
        baseURI = _newBaseURI;
    }

    function setFreezeMetadata() external onlyOwner {
        require(!isMetadataFrozen, "YAKO: Already frozen"); 
        isMetadataFrozen = true;
    }
    
    function whitelistMint(bytes32[] calldata _merkleProof) external nonReentrant {
        require(isWhitelistMintActive, "YAKO: Whitelist Mint is not opened"); 
        require(totalSupply < MAX_SUPPLY, "YAKO: Already the max supply"); 
        require(!whitelistClaimed[msg.sender], "YAKO: Already claimed"); 
        require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "YAKO: Invalid Merkle Proof"); 
        whitelistClaimed[msg.sender] = true;

        _safeMint(msg.sender, totalSupply++);
    }

    function publicMint() external nonReentrant {
        require(isPublicMintActive, "YAKO: Public Mint is not opened"); 
        require(totalSupply < MAX_SUPPLY, "YAKO: Already the max supply"); 
        require(!publicClaimed[msg.sender], "YAKO: Already claimed"); 
        publicClaimed[msg.sender] = true;

        _safeMint(msg.sender, totalSupply++);
    }

    function ownerMint(address _to) external onlyOwner {
        for (uint256 i = 0; i < OWNER_ALLOTMENT; i++) {
            _safeMint(_to, i);
        }

        totalSupply += OWNER_ALLOTMENT;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "YAKO: Nonexistent token"); 
        return string(
            abi.encodePacked(
                _baseURI(),
                tokenId.toString(),
                EXTENSION
                )
            );
    }
    
    function supportsInterface(bytes4 _interfaceId) public view virtual override (ERC721, ERC2981) returns (bool) {
        return
            ERC721.supportsInterface(_interfaceId) || super.supportsInterface(_interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}