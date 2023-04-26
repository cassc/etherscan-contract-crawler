pragma solidity ^0.8.17;

import "./ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "./DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract MetaRebelz is ERC721AQueryableUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, DefaultOperatorFiltererUpgradeable {
    uint256 public cost;   
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    address public withdrawWallet;
    bool public mintable;
    bool public preSale;
    string baseURI;
    bytes32 public merkleRoot;

    mapping(uint256 => bool) tokenProtected;

   /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializerERC721A initializer public {
        __ERC721A_init("MetaRebelz", "REBELZ");
        __ERC721AQueryable_init();
        OwnableUpgradeable.__Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
        cost = 0.083 ether;
        merkleRoot = 0;
        maxSupply = 8500;
        maxMintAmount = 10;
        mintable = false;
        baseURI = "";
        preSale = true;
        withdrawWallet = address(msg.sender);
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner
    {
        merkleRoot = merkleRootHash;
    }

    function verifyAddress(bytes32[] calldata _merkleProof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintAmount(uint256 _newMax) public onlyOwner {
        maxMintAmount = _newMax;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function toggleMintable() public onlyOwner {
        mintable = !mintable;
    }

    function togglePreSale() public onlyOwner {
        preSale = !preSale;
    }

    function setWithdrawWallet(address wallet) public onlyOwner {
        withdrawWallet = wallet;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool os, ) = payable(withdrawWallet).call{value: address(this).balance}("");
        require(os);
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function lockToken(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender);
            tokenProtected[tokenId] = true;
        }
    }

     function unlockToken(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender);
            tokenProtected[tokenId] = false;
        }
    }

    function lockToken(uint256 tokenId, bool isAdmin) public onlyOwner {
        require(isAdmin);
        tokenProtected[tokenId] = true;
    }

    function unlockToken(uint256 tokenId, bool isAdmin) public onlyOwner {
        require(isAdmin);
        tokenProtected[tokenId] = false;
    }

    function isLocked(uint256 tokenId) external view returns (bool) {
        return (true == tokenProtected[tokenId]);
    }

    function isUnlocked(uint256 tokenId) internal view returns (bool) {
        return (false == tokenProtected[tokenId]);
    }

    function airdrop(address to, uint256 _mintAmount) public onlyOwner {
        _mint(to, _mintAmount);
    }

    function mint(uint256 _mintAmount) external payable {
        require(mintable);
        require(!preSale);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(_totalMinted() + _mintAmount <= maxSupply);
        require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount);

        if (msg.sender != owner()) {            
            require(msg.value >= cost * _mintAmount);
        }

        _mint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable {
        require(mintable);
        require(preSale);
        require(verifyAddress(_merkleProof), "Not in whitelist");
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(_totalMinted() + _mintAmount <= maxSupply);
        require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount);

        if (msg.sender != owner()) {            
            require(msg.value >= cost * _mintAmount);
        }

        _mint(msg.sender, _mintAmount);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory _URI = _baseURI();
        return bytes(_URI).length != 0 ? string(abi.encodePacked(_URI, _toString(tokenId))) : '';
    }

    function _startTokenId() internal view virtual override(ERC721AUpgradeable) returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal whenNotPaused virtual override(ERC721AUpgradeable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable virtual 
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.safeTransferFrom(from, to, tokenId, data);
    }    
}