// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

error MustMintAtLeastOne();
error MaxTokenSupplyExceeded();
error MaxTokensPerTransactionExceeded(uint256 requested, uint256 maximum);
error InsufficientPayment(uint256 sent, uint256 required);
error InvalidMerkleProof();
error DiscountAlreadyClaimed();
error MintedMaxTokens();

/// @custom:security-contact TheNathanDrake @nathandrake
contract MemeLordDistrict is
  ERC721A,
  ERC721ABurnable,
  Pausable,
  Ownable,
  ERC2981
{
  uint256 public MINT_PRICE = 0.069 ether;
  uint256 public DISCOUNT_PRICE = 0.042 ether;
  uint8 public MAX_PURCHASE_PUBLIC = 5;
  uint8 public MAX_PURCHASE_DISCOUNT = 10;
  uint8 public MAX_TOKENS_PER_WALLET = 10;
  uint16 public MAX_SUPPLY = 420;
  bytes32 _merkleRoot;

  string private _baseTokenURI =
    'ipfs://bafybeignpas3zw6fhoenhy2ahl4bvucutu2xyqveqkjhveqmovcpi6buqa/';

  mapping(address => bool) public claimed;
  mapping(address => uint8) public mintedPerWallet;

  enum MintPhase {
    Closed,
    Discount,
    Public
  }

  MintPhase public currentPhase = MintPhase.Closed;

  constructor(
    bytes32 merkleRoot,
    address projectWallet,
    address nateWallet,
    address saintWallet,
    address hmooreWallet
  ) ERC721A('MemeLord District', 'MLD') {
    // check that all args are valid and not null
    require(
      projectWallet != address(0) &&
        nateWallet != address(0) &&
        saintWallet != address(0) &&
        hmooreWallet != address(0),
      'Invalid wallet address'
    );
    require(merkleRoot != bytes32(0), 'Invalid merkle root');

    _merkleRoot = merkleRoot;

    _setDefaultRoyalty(projectWallet, 690);

    // 1 token to dev as part of compensation, 5 each to founders, 4 reserved for project wallet
    _safeMint(projectWallet, 4);
    _safeMint(saintWallet, 5);
    _safeMint(hmooreWallet, 5);
    _safeMint(nateWallet, 1);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  // setter functions for basic mint settings
  function setBaseURI(string memory newBase) external onlyOwner {
    _baseTokenURI = newBase;
  }

  function setMerkleRoot(bytes32 newRoot) external onlyOwner {
    _merkleRoot = newRoot;
  }

  function setMintPhase(MintPhase newPhase) public onlyOwner {
    currentPhase = newPhase;
  }

  function setPublicMintPrice(uint256 newPrice) public onlyOwner {
    MINT_PRICE = newPrice;
  }

  function setDiscountMintPrice(uint256 newPrice) public onlyOwner {
    DISCOUNT_PRICE = newPrice;
  }

  function setMaxPurchaseCount(uint8 newMaxPurchaseCount) public onlyOwner {
    MAX_PURCHASE_PUBLIC = newMaxPurchaseCount;
  }

  // mint modifiers
  modifier whenInMintPhase(MintPhase expectedPhase) {
    require(currentPhase == expectedPhase, 'Invalid mint phase');
    _;
  }

  // mint functions
  function discountMint(
    uint8 numberOfTokens,
    bytes32[] calldata merkleProof
  ) external payable whenNotPaused whenInMintPhase(MintPhase.Discount) {
    if (numberOfTokens < 1) {
      revert MustMintAtLeastOne();
    }

    if (totalSupply() + numberOfTokens > MAX_SUPPLY) {
      revert MaxTokenSupplyExceeded();
    }

    if (numberOfTokens > MAX_PURCHASE_DISCOUNT) {
      revert MaxTokensPerTransactionExceeded(
        numberOfTokens,
        MAX_PURCHASE_DISCOUNT
      );
    }

    // check that the user has not minted more than the max allowed
    if (mintedPerWallet[msg.sender] + numberOfTokens > MAX_TOKENS_PER_WALLET) {
      revert MintedMaxTokens();
    }

    uint256 totalCost = DISCOUNT_PRICE * numberOfTokens;

    if (msg.value < totalCost) {
      revert InsufficientPayment(msg.value, totalCost);
    }

    if (claimed[msg.sender]) {
      revert DiscountAlreadyClaimed();
    }

    if (
      !MerkleProof.verify(
        merkleProof,
        _merkleRoot,
        keccak256(abi.encodePacked(_msgSender()))
      )
    ) {
      revert InvalidMerkleProof();
    }

    claimed[msg.sender] = true;

    mintedPerWallet[msg.sender] += numberOfTokens;
    _safeMint(msg.sender, numberOfTokens);
  }

  function publicMint(
    uint8 numberOfTokens
  ) external payable whenNotPaused whenInMintPhase(MintPhase.Public) {
    if (numberOfTokens < 1) {
      revert MustMintAtLeastOne();
    }

    if (totalSupply() + numberOfTokens > MAX_SUPPLY) {
      revert MaxTokenSupplyExceeded();
    }

    if (numberOfTokens > MAX_PURCHASE_PUBLIC) {
      revert MaxTokensPerTransactionExceeded(
        numberOfTokens,
        MAX_PURCHASE_PUBLIC
      );
    }

    if (mintedPerWallet[msg.sender] + numberOfTokens > MAX_TOKENS_PER_WALLET) {
      revert MintedMaxTokens();
    }

    uint256 totalCost = MINT_PRICE * numberOfTokens;

    if (msg.value < totalCost) {
      revert InsufficientPayment(msg.value, totalCost);
    }

    mintedPerWallet[msg.sender] += numberOfTokens;
    _safeMint(msg.sender, numberOfTokens);
  }

  // allows owner to bulk mint tokens for free
  function ownerMint(address to, uint8 numberOfTokens) external onlyOwner {
    if (totalSupply() + numberOfTokens > MAX_SUPPLY) {
      revert MaxTokenSupplyExceeded();
    }

    _safeMint(to, numberOfTokens);
  }

  // release ether to owner
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC2981, ERC721A, IERC721A) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}