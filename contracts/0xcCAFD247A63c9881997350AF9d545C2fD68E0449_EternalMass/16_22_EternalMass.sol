// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./interfaces/IBaseMetadata.sol";
import "./interfaces/IGenerateMetadata.sol";

contract EternalMass is
    ERC721,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    IBaseMetadata
{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 888;
    uint256 public constant FIRST_SALE_SUPPLY = 111;
    uint256 public totalSupply;
    uint256 private mintPrice;

    bytes32 public merkleRoot;

    string private _description;
    string private _externalUrl;

    address public baseAddress;

    bool public isAllowlistSaleActive;
    bool public isPublicSaleActive;
    bool public isMetadataFrozen;

    mapping (address => bool) private allowlistClaimed;
    mapping (address => bool) private publicClaimed;
    mapping (uint256 => bytes32) private objects;

    constructor() ERC721("Eternal Mass", "EM") {}

    function allowlistMint(bytes32[] calldata _merkleProof, uint256 _quantity) external payable nonReentrant {
        require(isAllowlistSaleActive, "EternalMass: Allowlist sale is not active");
        require(MerkleProof.verify(_merkleProof, merkleRoot,  keccak256(abi.encodePacked(msg.sender, _quantity))), "EternalMass: Invalid Merkle Proof");
        require(!allowlistClaimed[msg.sender], "EternalMass: Already claimed");
        require(msg.value == _quantity * mintPrice, "EternalMass: ETH is not enough");

        _commonMint(msg.sender, _quantity);
        allowlistClaimed[msg.sender] = true;
    }

    function publicMint() external payable nonReentrant {
        require(isPublicSaleActive, "EternalMass: Public sale is not active");
        require(!publicClaimed[msg.sender], "EternalMass: Already claimed"); 
        require(msg.value == mintPrice, "EternalMass: ETH is not enough");
        
        _commonMint(msg.sender, 1);
        publicClaimed[msg.sender] = true;
    }

    function ownerMint(address _to, uint256 _mintQuantity) external onlyOwner {        
        _commonMint(_to, _mintQuantity);
    }

    function _commonMint(address _to, uint256 _mintQuantity) internal {
        require(totalSupply + _mintQuantity <= _getMaxSupply(), "EternalMass: Exceed the max supply of this sale");

        for (uint256 i = 0; i < _mintQuantity; i++) {
            objects[totalSupply + i] = bytes32(abi.encodePacked(msg.sender, blockhash(block.number - 1)));
            _safeMint(_to, totalSupply + i);
        }

        totalSupply += _mintQuantity;

        if (totalSupply == FIRST_SALE_SUPPLY) {
            isPublicSaleActive = false;
            isAllowlistSaleActive = false;
        }
    }

    function setIsAllowlistSaleActive(bool _state) external onlyOwner {
        require(merkleRoot != bytes32(0), "EternalMass: MerkleRoot is not set");
        isAllowlistSaleActive = _state;
    }

    function setIsPublicSaleActive(bool _state) external onlyOwner {
        isPublicSaleActive = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setRoyalty(address _royaltyAddress, uint96 _royaltyFee) external onlyOwner {        
        _setDefaultRoyalty(_royaltyAddress, _royaltyFee);
    }
    
    modifier onlyNotFrozen {
        require(!isMetadataFrozen, "EternalMass: Already frozen"); 
        _;
    }

    function setFreezeMetadata() external onlyOwner onlyNotFrozen {
        isMetadataFrozen = true;
    }

    function setBaseAddress(address _baseAddress) external onlyOwner onlyNotFrozen {
        baseAddress = _baseAddress;
    }

    function setDescription(string memory _newDescription) external onlyOwner onlyNotFrozen {
        _description = _newDescription;
    }
    
    function setExternalUrl(string memory _newExternalUrl) external onlyOwner onlyNotFrozen {
        _externalUrl = _newExternalUrl;
    }

    modifier onlyBaseAddress {
        require(baseAddress == msg.sender, "EternalMass: Caller is not generateMetadata contract");
        _;
    }

    function seed(uint256 _input) public view onlyBaseAddress returns (uint256) {
        return uint256(keccak256(abi.encodePacked(objects[_input], _input)));
    }

    function generateGender(uint256 tokenId) external view onlyBaseAddress returns (string memory) {
        return (seed(tokenId) % 2 == 0) ? "male" : "female";
    }

    function description() external view returns (string memory) {
        return _description;
    }

    function externalUrl() external view returns (string memory) {
        return _externalUrl;
    }

    function getWave(uint256 tokenId) external view onlyBaseAddress returns (string memory) {
        return (tokenId < FIRST_SALE_SUPPLY) ? "1st" : "2nd";
    }

    function _getMaxSupply() internal view returns (uint256) {
        return (totalSupply < FIRST_SALE_SUPPLY) ? FIRST_SALE_SUPPLY : MAX_SUPPLY;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "EternalMass: Nonexistent token");
        return IGenerateMetadata(baseAddress).tokenMetadata(tokenId);
    }
    
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "EternalMass: Caller is not owner nor approved");
        _burn(tokenId);
    }

    function withdraw(address payable _receiptAddress) external onlyOwner {
        require(_receiptAddress != address(0), "EternalMass: Invalid receipt address");
        _receiptAddress.transfer(address(this).balance);
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

    function supportsInterface(bytes4 _interfaceId) public view virtual override (ERC721, ERC2981) returns (bool) {
        return
            ERC721.supportsInterface(_interfaceId) || super.supportsInterface(_interfaceId);
    }
}