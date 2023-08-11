// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "./mason/utils/Administrable.sol";
import "./mason/utils/EIP712Common.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";

error AllowlistDisabled();
error ExceedsMaxPerWallet();
error ExceedsMaxSupply();
error HoldingContractNotSet();
error InsufficientFunds();
error MintingDisabled();
error NotApproved();
error RoyaltiesTooHigh();
error TokenContractNotSet();

contract AkuWorlds is Administrable, EIP712Common {
  address public holdingWallet;
  address public onCyberContract;
  address public treasuryAddress;
  uint256 public maxPerWallet = 1;
  uint256 public maxSupply;
  uint256 public tokenId;

  uint256 public totalSupply;
  uint256 public mintPrice = 4000000000000000;
  uint256 public allowlistPrice = 2000000000000000;

  bool public allowlistEnabled = true;
  bool public mintingEnabled = true;

  mapping(address => uint256) private quantityMinted;

  constructor(
    address _contractAddress,
    address _holdingWallet,
    uint256 _tokenId,
    uint256 _maxSupply,
    address _treasuryAddress
  ) {
    onCyberContract = _contractAddress;
    holdingWallet = _holdingWallet;
    tokenId = _tokenId;
    maxSupply = _maxSupply;
    treasuryAddress = _treasuryAddress;
  }

  // **** Setters **** //

  function setMintPrice(uint256 price) external onlyOperatorsAndOwner {
    mintPrice = price;
  }

  function setTreasuryAddress(address _treasuryAddress) external onlyOperatorsAndOwner {
    treasuryAddress = _treasuryAddress;
  }

  function setAllowlistPrice(uint256 price) external onlyOperatorsAndOwner {
    allowlistPrice = price;
  }

  function setHoldingWallet(address wallet) external onlyOperatorsAndOwner {
    holdingWallet = wallet;
  }

  function setOnCyberContract(address contractAddress) external onlyOperatorsAndOwner {
    onCyberContract = contractAddress;
  }

  function setTokenId(uint256 _tokenId) external onlyOperatorsAndOwner {
    tokenId = _tokenId;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOperatorsAndOwner {
    maxSupply = _maxSupply;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) external onlyOperatorsAndOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setAllowlistEnabled(bool _allowlistEnabled) external onlyOperatorsAndOwner {
    allowlistEnabled = _allowlistEnabled;
  }

  function setMintingEnabled(bool _mintingEnabled) external onlyOperatorsAndOwner {
    mintingEnabled = _mintingEnabled;
  }

  // **** Getters **** //

  function getAllowlistEligibility(bytes calldata signature) external view requiresAllowlist(signature) returns (bool) {
    return true;
  }

  function getRemainingMints(address wallet) external view returns (uint256) {
    return maxPerWallet - quantityMinted[wallet];
  }

  // **** Minting Functions **** //

  function mint(
    uint256 quantity
  )
    external
    payable
    requiresMintingEnabled
    noContracts
    requireTokenApproval
    requireAvailableSupply(quantity)
    enforceMaxPerWallet(quantity)
  {
    if (msg.value < mintPrice * quantity) revert InsufficientFunds();

    totalSupply += quantity;
    quantityMinted[msg.sender] += quantity;

    _transferToken(msg.sender, quantity);
  }

  function allowlistMint(
    uint256 quantity,
    bytes calldata signature
  )
    external
    payable
    noContracts
    requireTokenApproval
    requireAvailableSupply(quantity)
    enforceMaxPerWallet(quantity)
    requiresAllowlist(signature)
    requiresAllowlistEnabled
  {
    if (msg.value < allowlistPrice * quantity) revert InsufficientFunds();

    totalSupply += quantity;
    quantityMinted[msg.sender] += quantity;

    _transferToken(msg.sender, quantity);
  }

  function airdrop(
    address recipient,
    uint256 quantity
  ) external onlyOperatorsAndOwner requireTokenApproval requireAvailableSupply(quantity) {
    totalSupply += quantity;

    _transferToken(recipient, quantity);
  }

  function _transferToken(address recipient, uint256 quantity) internal {
    IERC1155(onCyberContract).safeTransferFrom(holdingWallet, recipient, tokenId, quantity, "");
  }

  // **** Withdrawal Functions **** //

  function release() external virtual onlyOperatorsAndOwner {
    uint256 balance = address(this).balance;
    Address.sendValue(payable(treasuryAddress), balance);
  }

  // **** Modifiers **** //

  modifier requireTokenApproval() {
    if (!IERC1155(onCyberContract).isApprovedForAll(holdingWallet, address(this))) revert NotApproved();
    _;
  }

  modifier enforceMaxPerWallet(uint256 quantity) {
    if (quantityMinted[msg.sender] + quantity > maxPerWallet) revert ExceedsMaxPerWallet();
    _;
  }

  modifier requireAvailableSupply(uint256 quantity) {
    if (totalSupply + quantity > maxSupply) revert ExceedsMaxSupply();
    _;
  }

  modifier requiresAllowlistEnabled() {
    if (!allowlistEnabled) revert AllowlistDisabled();
    _;
  }

  modifier requiresMintingEnabled() {
    if (!mintingEnabled) revert MintingDisabled();
    _;
  }
}