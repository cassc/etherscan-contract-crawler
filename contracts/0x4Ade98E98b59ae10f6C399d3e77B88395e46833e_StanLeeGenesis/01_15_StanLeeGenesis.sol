/***
 *                 _                 _
 *     ___   __ _ | |_  __ _   __ _ (_)
 *    / __| / _` || __|/ _` | / _` || |
 *    \__ \| (_| || |_| (_| || (_| || |
 *    |___/ \__,_| \__|\__,_| \__, ||_|
 *                               |_|
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract StanLeeGenesis is ERC721A, Ownable, AccessControl, ReentrancyGuard {
  using Strings for uint256;

  uint256 private constant maxSupply = 10000;
  uint256 private maxSupplyTotal = 10000;
  uint256 private slcPrice = 0.12 ether;
  uint256 private pwlPrice = 0.15 ether;
  uint256 private wlPrice = 0.20 ether;
  uint256 private publicPrice = 0.22 ether;
  uint256 private maxPerWallet = 3;
  bool public isTransferPaused = false;
  bool public isMintPaused = false;
  bool public slcStarted = false;
  bool public pwlStarted = false;
  bool public wlStarted = false;
  bool public publicStarted = false;
  bool private isRevealed = false;
  string private uriPrefix;
  string private hiddenMetadataURI;
  bytes32 public slcMerkleRoot;
  bytes32 public pwlMerkleRoot;
  bytes32 public wlMerkleRoot;
  address private withdrawWallet;
  mapping(address => uint256) private slcMinted;
  mapping(address => uint256) private pwlMinted;
  mapping(address => uint256) private wlMinted;

  constructor() ERC721A("Stan Lee Genesis", "SLG") {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  modifier mintCompliance(uint256 _mintAmount, uint256 _totalAmount) {
    require(!isMintPaused, "Minting is paused.");
    require((totalSupply() + _mintAmount) <= _totalAmount, "Mint amount exceeds allocated supply.");
    _;
  }

  function addressToString() internal view returns (string memory) {
    return Strings.toHexString(uint160(_msgSender()), 20);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "No data exists for provided tokenId.");

    if (isRevealed == false) {
      return hiddenMetadataURI;
    }

    return bytes(uriPrefix).length > 0 ? string(abi.encodePacked(uriPrefix, tokenId.toString(), ".json")) : "";
  }

  function slcMint(
    uint256 _mintAmount,
    uint256 _totalMintAmount,
    bytes32[] calldata _merkleProof
  ) external payable mintCompliance(_mintAmount, maxSupplyTotal) {
    bytes32 leaf = keccak256(abi.encodePacked(addressToString(), "-", _totalMintAmount.toString()));
    uint256 minted = slcMinted[_msgSender()];

    require(slcStarted, "StanLee Certificate sale is paused.");
    require(msg.value >= (slcPrice * _mintAmount), "Insufficient balance to mint.");
    require(
      MerkleProof.verify(_merkleProof, slcMerkleRoot, leaf),
      "Invalid proof, this wallet is not allowed to mint the given number."
    );
    require((minted + _mintAmount) <= _totalMintAmount, "Selected number of mints will exceed the allowed limit.");

    slcMinted[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  function pwlMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    external
    payable
    mintCompliance(_mintAmount, maxSupplyTotal)
  {
    uint256 minted = pwlMinted[_msgSender()];
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(pwlStarted, "Premium Whitelist sale is paused.");
    require(msg.value >= (pwlPrice * _mintAmount), "Insufficient balance to mint.");
    require(
      (minted + _mintAmount) <= maxPerWallet,
      "Selected number of mints will exceed the maximum amount of allowed per wallet."
    );
    require(
      MerkleProof.verify(_merkleProof, pwlMerkleRoot, leaf),
      "Invalid proof, this wallet is not allowed to mint using Premium Whitelist."
    );

    pwlMinted[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  function wlMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    external
    payable
    mintCompliance(_mintAmount, maxSupplyTotal)
  {
    uint256 minted = wlMinted[_msgSender()];
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(wlStarted, "Whitelist sale is paused.");
    require(msg.value >= (wlPrice * _mintAmount), "Insufficient balance to mint.");
    require(
      (minted + _mintAmount) <= maxPerWallet,
      "Selected number of mints will exceed the maximum amount of allowed per wallet."
    );
    require(
      MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf),
      "Invalid proof, this wallet is not allowed to mint using Whitelist."
    );

    wlMinted[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  function publicMint(uint256 _mintAmount) external payable mintCompliance(_mintAmount, maxSupplyTotal) {
    require(publicStarted, "Public sale is paused.");
    require(msg.value >= (publicPrice * _mintAmount), "Insufficient balance to mint.");

    _safeMint(_msgSender(), _mintAmount);
  }

  function getSlcMinted(address _wallet) external view returns (uint256) {
    return slcMinted[_wallet];
  }

  function getPwlMinted(address _wallet) external view returns (uint256) {
    return pwlMinted[_wallet];
  }

  function getWlMinted(address _wallet) external view returns (uint256) {
    return wlMinted[_wallet];
  }

  // admin
  function mintFor(uint256 _mintAmount, address _receiver)
    external
    mintCompliance(_mintAmount, maxSupplyTotal)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _safeMint(_receiver, _mintAmount);
  }

  function updateMaxSupplyTotal(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // collection can be capped, if needed, but can never increase from initial total
    require(_number <= maxSupply, "Public supply can not exceed total defined.");
    require(_number >= totalSupply(), "Supply can not be less than already minted.");

    maxSupplyTotal = _number;
  }

  function updateSlcPrice(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    slcPrice = _number;
  }

  function updatePwlPrice(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    pwlPrice = _number;
  }

  function updateWlPrice(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    wlPrice = _number;
  }

  function updatePublicPrice(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    publicPrice = _number;
  }

  function updateMaxPerWallet(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxPerWallet = _number;
  }

  function toggleTransfer(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isTransferPaused = _state;
  }

  function toggleMint(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isMintPaused = _state;
  }

  function toggleSlcSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    slcStarted = _state;
  }

  function togglePwlSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    pwlStarted = _state;
  }

  function toggleWlSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    wlStarted = _state;
  }

  function togglePublicSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    publicStarted = _state;
  }

  function reveal() external onlyRole(DEFAULT_ADMIN_ROLE) {
    isRevealed = true;
  }

  function updateURIPrefix(string calldata _uriPrefix) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uriPrefix = _uriPrefix;
  }

  function setHiddenMetadataURI(string memory _hiddenMetadataURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
    hiddenMetadataURI = _hiddenMetadataURI;
  }

  function updateSlcRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    slcMerkleRoot = _merkleRoot;
  }

  function updatePwlRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    pwlMerkleRoot = _merkleRoot;
  }

  function updateWlRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    wlMerkleRoot = _merkleRoot;
  }

  function updateWithdrawWallet(address _withdrawWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
    withdrawWallet = _withdrawWallet;
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    require(withdrawWallet != address(0), "withdraw wallet is not set.");

    (bool success, ) = payable(withdrawWallet).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }
}