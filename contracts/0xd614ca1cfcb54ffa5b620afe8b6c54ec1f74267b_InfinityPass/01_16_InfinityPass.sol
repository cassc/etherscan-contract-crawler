//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract InfinityPass is ERC721A, ERC2981, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  bytes32 private ALLOWLIST_MERKLE_ROOT;

  uint256 private MAX_MINT_SUPPLY = 100;
   string private BASE_URI;
   string private CLAIMED_BASE_URI;

  uint256 public MAX_SUPPLY = 111;
  uint256 public MAX_MINT_FOR_PUBLIC = 3;
  uint256 public PRICE = 0.6 ether;
  uint256 public MINT_PHASE = 0;
  address public CLAIMER = address(0);
     bool public DEV_MINTED = false;

  event InfinityPassClaimed(uint256 indexed tokenId);

  mapping(address => uint256) private allowlistMinters;
  mapping(address => uint256) private publicMinters;
  mapping(uint256 => bool) private claimedPasses;

  constructor(address royaltyReceiver) ERC721A("Infinity Pass", "IP") {
    _setDefaultRoyalty(royaltyReceiver, 500);
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "IP: contract calls not allowed.");
    _;
  }

  modifier callerCanClaim() {
    require(CLAIMER == msg.sender || owner() == msg.sender, "IP: caller is not permitted to update the claim state.");
    _;
  }

  modifier validateMint() {
    require(MINT_PHASE > 0, "IP: mint is not live.");
    require(_totalMinted() + 1 <= MAX_MINT_SUPPLY, "IP: sold out.");
    _;
  }
  
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = claimedPasses[tokenId] ? _claimedBaseURI() : _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }

  function _claimedBaseURI() internal view virtual returns (string memory) {
    return CLAIMED_BASE_URI;
  }

  function allowlistMint(uint256 quantity, uint256 allocation, bytes32[] calldata proof) external payable nonReentrant callerIsUser validateMint {
    require(MINT_PHASE == 1, "IP: allowlist mint is not live.");
    require(_totalMinted() + quantity <= MAX_MINT_SUPPLY, "IP: quantity will exceed supply.");
    require(MerkleProof.verify(proof, ALLOWLIST_MERKLE_ROOT, keccak256(abi.encodePacked(msg.sender, allocation))), "IP: invalid proof.");
    require(allowlistMinters[msg.sender] + 1 <= allocation, "IP: already max minted allowlist allocation.");
    require(allowlistMinters[msg.sender] + quantity <= allocation, "IP: mint quantity will exceed allowlist allocation.");
    require(msg.value == PRICE * quantity, "IP: incorrect ether value.");

    allowlistMinters[msg.sender] += quantity;
    _mint(msg.sender, quantity);
  }

  function publicMint(uint256 quantity) external payable nonReentrant callerIsUser validateMint {
    require(MINT_PHASE == 2, "IP: public mint is not live.");
    require(_totalMinted() + quantity <= MAX_MINT_SUPPLY, "IP: quantity will exceed supply.");
    require(publicMinters[msg.sender] + 1 <= MAX_MINT_FOR_PUBLIC, "IP: already max minted public allocation.");
    require(publicMinters[msg.sender] + quantity <= MAX_MINT_FOR_PUBLIC, "IP: quantity will exceed max mints.");
    require(msg.value == PRICE * quantity, "IP: incorrect ether value.");

    publicMinters[msg.sender] += quantity;
    _mint(msg.sender, quantity);
  }
  
  function devMint(uint256 quantity) external onlyOwner {
    require(_totalMinted() + 1 <= MAX_SUPPLY, "IP: sold out.");
    require(_totalMinted() + quantity <= MAX_SUPPLY, "IP: mint quantity will exceed supply.");
    require(DEV_MINTED == false, "IP: dev minted already.");
    
    DEV_MINTED = true;
    _mint(msg.sender, quantity);
  }

  function claim(uint256[] memory tokenIds) external nonReentrant callerCanClaim {
    for (uint i = 0; i < tokenIds.length; i++) {
      claimedPasses[tokenIds[i]] = true;
      emit InfinityPassClaimed(tokenIds[i]);
    }
  }

  function claimed(uint256 tokenId) public view returns (bool) {
    return claimedPasses[tokenId];
  }

  function setRoyalty(address receiver, uint96 value) external onlyOwner {
    _setDefaultRoyalty(receiver, value);
  }

  function setAllowlistMerkleRoot(bytes32 newAllowlistMerkleRoot) external onlyOwner {
    ALLOWLIST_MERKLE_ROOT = newAllowlistMerkleRoot;
  }
  
  function setURIs(string memory newBaseURI, string memory newClaimedBaseURI) external onlyOwner {
    BASE_URI = newBaseURI;
    CLAIMED_BASE_URI = newClaimedBaseURI;
  }

  function setPrice(uint256 newPrice) external onlyOwner {
    PRICE = newPrice;
  }

  function setMaxSupply(uint256 newMaxSupply, uint256 newMaxMintSupply) external onlyOwner {
    require(newMaxSupply > 0 && newMaxMintSupply > 0, "IP: max supply cannot be 0.");
    require(newMaxSupply > newMaxMintSupply, "IP: max mint supply cannot exceed mint supply.");
    require(newMaxSupply >= _totalMinted(), "IP: max mint supply cannot be less than total supply.");
    MAX_SUPPLY = newMaxSupply;
    MAX_MINT_SUPPLY = newMaxMintSupply;
  }

  function setMaxMintForPublic(uint256 newMaxMintForPublic) external onlyOwner {
    MAX_MINT_FOR_PUBLIC = newMaxMintForPublic;
  }

  function setMintPhase(uint256 newMintPhase) external onlyOwner {
    MINT_PHASE = newMintPhase;
  }

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

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    Address.sendValue(payable(owner()), balance);
  }
}