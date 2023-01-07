// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @creator NFTinit.com
/// @author Racherin - racherin.eth

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract NFTinitDesktop is ERC721, DefaultOperatorFilterer, Ownable, ERC2981 {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  enum SalePhase {
    Closed,
    FoundersPresale,
    FoundersSale,
    MemberSale,
    PublicSale
  }

  struct SaleConfig {
    SalePhase phase;
    uint256 price;
    uint256 maxPerAddress;
    bytes32 merkleRoot;
  }

  SaleConfig public saleConfig;

  mapping(SalePhase => mapping(address => uint256)) public mintedCount;

  uint256 public constant MAX_SUPPLY = 240;

  uint256 public constant PHASE1_PRICE = 2.25 ether;
  uint256 public constant PHASE2_PRICE = 2.25 ether;
  uint256 public constant PHASE3_PRICE = 2.75 ether;
  uint256 public constant PHASE4_PRICE = 3 ether;

  uint256 public constant PHASE1_PER_WL = 2;
  uint256 public constant PHASE3_PER_WL = 1;
  uint256 public constant PHASE4_PER_WL = 1;

  string public baseURI;
  uint256 public teamMinted;

  constructor(
    address receiver,
    uint96 feeNumerator
  ) ERC721("NFTinit Desktop", "INIT") {
    _tokenIdCounter.increment();
    _setDefaultRoyalty(receiver, feeNumerator);
    saleConfig = SaleConfig({
      phase: SalePhase.Closed,
      price: 0,
      maxPerAddress: 0,
      merkleRoot: bytes32(0)
    });
  }

  function verifyMerkleProof(
    bytes32 leaf,
    bytes32[] calldata proof,
    bytes32 root
  ) internal pure returns (bool) {
    return MerkleProof.verify(proof, root, leaf);
  }

  function checkAndUpdateMintedCount(
    SalePhase phase,
    uint256 quantity
  ) private {
    mintedCount[phase][msg.sender] += quantity;
  }

  modifier checkPrice(SalePhase phase, uint256 quantity) {
    require(msg.value == quantity * saleConfig.price, "Incorrect price.");
    _;
  }

  function _mintBatch(address to, uint256 amount) internal {
    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = _tokenIdCounter.current();
      _tokenIdCounter.increment();
      _safeMint(to, tokenId);
    }
  }

  function teamMint(address to, uint256 amount) external onlyOwner {
    require(teamMinted + amount <= MAX_SUPPLY, "Max supply reached.");

    teamMinted += amount;
    _mintBatch(to, amount);
  }

  function mintFoundersPresale(
    uint256 quantity,
    bytes32[] calldata merkleProof
  ) external payable checkPrice(SalePhase.FoundersPresale, quantity) {
    require(
      saleConfig.phase == SalePhase.FoundersPresale,
      "Sale phase is not FoundersPresale."
    );
    require(
      mintedCount[SalePhase.FoundersPresale][msg.sender] + quantity <=
        saleConfig.maxPerAddress,
      "Quantity exceeds max per address."
    );
    require(
      _tokenIdCounter.current() + quantity <= MAX_SUPPLY,
      "Max supply reached."
    );

    require(
      verifyMerkleProof(
        keccak256(abi.encodePacked(msg.sender)),
        merkleProof,
        saleConfig.merkleRoot
      ),
      "Invalid merkle proof."
    );

    checkAndUpdateMintedCount(SalePhase.FoundersPresale, quantity);
    _mintBatch(msg.sender, quantity);
  }

  function mintFoundersSale(
    uint256 quantity,
    bytes32[] calldata merkleProof
  ) external payable checkPrice(SalePhase.FoundersSale, quantity) {
    require(
      saleConfig.phase == SalePhase.FoundersSale,
      "Sale phase is not FoundersSale."
    );
    require(
      _tokenIdCounter.current() + quantity <= MAX_SUPPLY,
      "Max supply reached."
    );

    require(
      verifyMerkleProof(
        keccak256(abi.encodePacked(msg.sender)),
        merkleProof,
        saleConfig.merkleRoot
      ),
      "Invalid merkle proof."
    );

    checkAndUpdateMintedCount(SalePhase.FoundersSale, quantity);
    _mintBatch(msg.sender, quantity);
  }

  function mintMemberSale(
    uint256 quantity,
    bytes32[] calldata merkleProof
  ) external payable checkPrice(SalePhase.MemberSale, quantity) {
    require(
      saleConfig.phase == SalePhase.MemberSale,
      "Sale phase is not MemberSale."
    );
    require(
      mintedCount[SalePhase.MemberSale][msg.sender] + quantity <=
        saleConfig.maxPerAddress,
      "Quantity exceeds max per address."
    );
    require(
      _tokenIdCounter.current() + quantity <= MAX_SUPPLY,
      "Max supply reached."
    );

    require(
      verifyMerkleProof(
        keccak256(abi.encodePacked(msg.sender)),
        merkleProof,
        saleConfig.merkleRoot
      ),
      "Invalid merkle proof."
    );

    checkAndUpdateMintedCount(SalePhase.MemberSale, quantity);
    _mintBatch(msg.sender, quantity);
  }

  function mintPublicSale(
    uint256 quantity
  ) external payable checkPrice(SalePhase.PublicSale, quantity) {
    require(
      saleConfig.phase == SalePhase.PublicSale,
      "Sale phase is not PublicSale."
    );
    require(
      mintedCount[SalePhase.PublicSale][msg.sender] + quantity <=
        saleConfig.maxPerAddress,
      "Quantity exceeds max per address."
    );
    require(
      _tokenIdCounter.current() + quantity <= MAX_SUPPLY,
      "Max supply reached."
    );

    checkAndUpdateMintedCount(SalePhase.PublicSale, quantity);
    _mintBatch(msg.sender, quantity);
  }

  function startFoundersPresale(bytes32 merkleRoot) external onlyOwner {
    saleConfig = SaleConfig({
      phase: SalePhase.FoundersPresale,
      price: PHASE1_PRICE,
      maxPerAddress: PHASE1_PER_WL,
      merkleRoot: merkleRoot
    });
  }

  function startFoundersSale(bytes32 merkleRoot) external onlyOwner {
    saleConfig = SaleConfig({
      phase: SalePhase.FoundersSale,
      price: PHASE2_PRICE,
      maxPerAddress: 0,
      merkleRoot: merkleRoot
    });
  }

  function startMemberSale(bytes32 merkleRoot) external onlyOwner {
    saleConfig = SaleConfig({
      phase: SalePhase.MemberSale,
      price: PHASE3_PRICE,
      maxPerAddress: PHASE3_PER_WL,
      merkleRoot: merkleRoot
    });
  }

  function startPublicSale() external onlyOwner {
    saleConfig = SaleConfig({
      phase: SalePhase.PublicSale,
      price: PHASE4_PRICE,
      maxPerAddress: PHASE4_PER_WL,
      merkleRoot: bytes32(0)
    });
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function setSaleConfig(SaleConfig calldata _saleConfig) external onlyOwner {
    saleConfig = _saleConfig;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function changeRoyaltyData(
    address receiver,
    uint96 feeNumerator
  ) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function _baseURI() internal view override(ERC721) returns (string memory) {
    return baseURI;
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIdCounter.current() - 1;
  }

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No balance to withdraw.");

    _withdraw(owner(), address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) internal {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "INIT: Transfer failed.");
  }
}