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

contract CubeX is ERC721A, Ownable, AccessControl, ReentrancyGuard {
  using Strings for uint256;

  uint256 private constant maxSupply = 10300;
  uint256 private maxSupplyTotal = 10300;
  uint256 private maxSupplyGen1 = 2300;
  uint256 private maxSupplyGen2 = 4300;

  uint256 private gen1Price = 0.15 ether;
  uint256 private constant gen2Price = 0.175 ether;
  uint256 private constant bgkPrice = 0.185 ether;
  uint256 private constant whitelistPrice = 0.2 ether;
  uint256 private constant publicPrice = 0.225 ether;
  uint256 private constant maxPerGen1 = 5;
  uint256 private constant maxPerGen2 = 5;
  uint256 private constant maxPerApiens = 1;
  uint256 private maxPerWallet = 2;
  uint256 private maxPerWalletPublic = 3;

  bool public paused = false;
  bool public gen1Started = false;
  bool public gen2Started = false;
  bool public bgkStarted = false;
  bool public whitelistStarted = false;
  bool public publicStarted = false;
  bool private revealed = false;

  string private uriPrefix;
  string private hiddenMetadataURI;
  bytes32 public gen1Root;
  bytes32 public gen2Root;
  bytes32 public bgkRoot;
  bytes32 public whitelistRoot;

  address public withdrawWallet;

  mapping(address => uint256) private gen1Used;
  mapping(address => uint256) private gen2Used;
  mapping(address => uint256) private bgkUsed;
  mapping(address => uint256) private whitelistUsed;
  mapping(address => uint256) private publicUsed;
  mapping(address => bool) private apiensUsed;

  IERC721 private bgk;

  constructor(string memory _hiddenMetadataURI) ERC721A("CubeX NFTs", "CXN") {
    bgk = IERC721(0x3A472c4D0dfbbb91ed050d3bb6B3623037c6263c);

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    setHiddenMetadataURI(_hiddenMetadataURI);
  }

  modifier mintCompliance(
    uint256 _mintAmount,
    uint256 _maxPerTx,
    uint256 _maxTotal
  ) {
    require(!paused, "Minting is paused.");
    require(_mintAmount <= _maxPerTx, "Mint amount exceeds max per transaction.");
    require((totalSupply() + _mintAmount) <= _maxTotal, "Mint amount exceeds allocated supply.");
    _;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "No data exists for provided tokenId.");

    if (revealed == false) {
      return hiddenMetadataURI;
    }

    return bytes(uriPrefix).length > 0 ? string(abi.encodePacked(uriPrefix, tokenId.toString(), ".json")) : "";
  }

  function getOwnerTokens(address _owner) external view returns (uint256[] memory) {
    uint256 ownerBalance = balanceOf(_owner);
    uint256[] memory ownerTokens = new uint256[](ownerBalance);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerBalance && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownerTokens[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownerTokens;
  }

  function gen1Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    external
    payable
    mintCompliance(_mintAmount, maxPerGen1, maxSupplyGen1)
  {
    uint256 minted = gen1Used[_msgSender()];

    require(gen1Started, "Bapes Genesis 1 sale is paused.");
    require(msg.value >= (gen1Price * _mintAmount), "Insufficient balance to mint.");
    require(
      (minted + _mintAmount) <= maxPerGen1,
      "Selected number of mints will exceed the maximum amount of allowed per wallet."
    );

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(
      MerkleProof.verify(_merkleProof, gen1Root, leaf),
      "Invalid proof, this wallet is not authorized to mint using Bapes Genesis 1."
    );

    gen1Used[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  function gen2Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    external
    payable
    mintCompliance(_mintAmount, maxPerGen2, maxSupplyGen2)
  {
    uint256 minted = gen2Used[_msgSender()];

    require(gen2Started, "Bapes Future sale is paused.");
    require(msg.value >= (gen2Price * _mintAmount), "Insufficient balance to mint.");
    require(
      (minted + _mintAmount) <= maxPerGen2,
      "Selected number of mints will exceed the maximum amount of allowed per wallet."
    );

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(
      MerkleProof.verify(_merkleProof, gen2Root, leaf),
      "Invalid proof, this wallet is not authorized to mint using Bapes Future."
    );

    gen2Used[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  function bgkMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable {
    uint256 minted = bgkUsed[_msgSender()];
    uint256 balance = bgk.balanceOf(_msgSender());

    require(!paused, "Minting is paused.");
    require(bgkStarted, "Bapes Genesis Key sale is paused.");
    require(_mintAmount <= balance, "You do not have enough BGKs to mint selected amount of tokens.");
    require((totalSupply() + _mintAmount) <= maxSupplyTotal, "Mint amount exceeds allocated supply.");
    require((minted + _mintAmount) <= balance, "Selected number of mints will exceed the amount of BGKs you have.");
    require(msg.value >= (bgkPrice * _mintAmount), "Insufficient balance to mint.");

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(
      MerkleProof.verify(_merkleProof, bgkRoot, leaf),
      "Invalid proof, this wallet is not authorized to mint using BGK."
    );

    bgkUsed[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  function apiensMint(bytes32[] calldata _merkleProof) external payable {
    bool minted = apiensUsed[_msgSender()];

    require(!paused, "Minting is paused.");
    require(bgkStarted, "Apiens sale is paused.");
    require(!minted, "This wallet has already minted.");
    require((totalSupply() + maxPerApiens) <= maxSupplyTotal, "Mint amount exceeds allocated supply.");
    require(msg.value >= bgkPrice, "Insufficient balance to mint.");

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(MerkleProof.verify(_merkleProof, bgkRoot, leaf), "Invalid proof, this wallet is not authorized to mint.");

    apiensUsed[_msgSender()] = true;

    _safeMint(_msgSender(), maxPerApiens);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    external
    payable
    mintCompliance(_mintAmount, maxPerWallet, maxSupplyTotal)
  {
    uint256 minted = whitelistUsed[_msgSender()];

    require(whitelistStarted, "Whitelist sale is paused.");
    require(
      (minted + _mintAmount) <= maxPerWallet,
      "Selected number of mints will exceed the maximum amount of allowed per wallet."
    );
    require(msg.value >= (whitelistPrice * _mintAmount), "Insufficient balance to mint.");

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(MerkleProof.verify(_merkleProof, whitelistRoot, leaf), "Invalid proof, this wallet is not whitelisted.");

    whitelistUsed[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  function publicMint(uint256 _mintAmount) external payable {
    uint256 minted = publicUsed[_msgSender()];

    require(!paused, "Minting is paused.");
    require(publicStarted, "Public sale is paused.");
    require(
      (minted + _mintAmount) <= maxPerWalletPublic,
      "Selected number of mints will exceed the maximum amount of allowed per wallet."
    );
    require((totalSupply() + _mintAmount) <= maxSupplyTotal, "Mint amount exceeds allocated supply.");
    require(msg.value >= (publicPrice * _mintAmount), "Insufficient balance to mint.");

    publicUsed[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  // admin
  function setHiddenMetadataURI(string memory _hiddenMetadataURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    hiddenMetadataURI = _hiddenMetadataURI;
  }

  function mintFor(uint256 _mintAmount, address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!paused, "Minting is paused.");
    require((totalSupply() + _mintAmount) <= maxSupplyTotal, "Mint amount exceeds allocated supply.");

    _safeMint(_receiver, _mintAmount);
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    require(withdrawWallet != address(0), "Withdraw wallet is not set.");

    (bool success, ) = payable(withdrawWallet).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }

  function updateWithdrawWallet(address _withdrawWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
    withdrawWallet = _withdrawWallet;
  }

  function updatePriceGen1() external onlyRole(DEFAULT_ADMIN_ROLE) {
    gen1Price = gen2Price;
  }

  function updateMaxSupplyGen1(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_number <= maxSupplyTotal, "Genesis 1 supply can not exceed total defined.");

    maxSupplyGen1 = _number;
  }

  function updateMaxSupplyTotal(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // collection can be capped, if needed, but can never increase from initial total
    require(_number <= maxSupply, "Public supply can not exceed total defined.");

    maxSupplyTotal = _number;
  }

  function updateMaxPerWallet(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxPerWallet = _number;
  }

  function updateURIPrefix(string calldata _uriPrefix) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uriPrefix = _uriPrefix;
  }

  function reveal() external onlyRole(DEFAULT_ADMIN_ROLE) {
    revealed = true;
  }

  function togglePause(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    paused = _state;
  }

  function toggleGen1Sale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    gen1Started = _state;
  }

  function toggleGen2Sale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    gen2Started = _state;
  }

  function toggleBGKSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    bgkStarted = _state;
  }

  function toggleWhitelistSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    whitelistStarted = _state;
  }

  function togglePublicSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    publicStarted = _state;
  }

  function updateGen1Root(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    gen1Root = _merkleRoot;
  }

  function updateGen2Root(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    gen2Root = _merkleRoot;
  }

  function updateBgkRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    bgkRoot = _merkleRoot;
  }

  function updateWhitelistRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    whitelistRoot = _merkleRoot;
  }
}