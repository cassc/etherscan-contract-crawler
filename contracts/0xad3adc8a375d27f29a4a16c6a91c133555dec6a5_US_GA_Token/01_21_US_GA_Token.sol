// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { DefaultOperatorFilterer } from "./royalty/DefaultOperatorFilterer.sol";
import { VRFConsumerBase } from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//   _______      ________       _______      ________
//  /  ___  \    |\   __  \     /  ___  \    |\_____  \
// /__/|_/  /|   \ \  \|\  \   /__/|_/  /|   \|____|\ /_
// |__|//  / /    \ \  \\\  \  |__|//  / /         \|\  \
//     /  /_/__    \ \  \\\  \     /  /_/__       __\_\  \
//    |\________\   \ \_______\   |\________\    |\_______\
//     \|_______|    \|_______|    \|_______|    \|_______|

//  ___  ___           ________                ___       __       ________      _____ ______       _______       ________       ________           ________      ________    _______       ________
// |\  \|\  \         |\   ____\              |\  \     |\  \    |\   __  \    |\   _ \  _   \    |\  ___ \     |\   ___  \    |\   ____\         |\   __  \    |\   __  \  |\  ___ \     |\   ___  \
// \ \  \\\  \        \ \  \___|_             \ \  \    \ \  \   \ \  \|\  \   \ \  \\\__\ \  \   \ \   __/|    \ \  \\ \  \   \ \  \___|_        \ \  \|\  \   \ \  \|\  \ \ \   __/|    \ \  \\ \  \
//  \ \  \\\  \        \ \_____  \             \ \  \  __\ \  \   \ \  \\\  \   \ \  \\|__| \  \   \ \  \_|/__   \ \  \\ \  \   \ \_____  \        \ \  \\\  \   \ \   ____\ \ \  \_|/__   \ \  \\ \  \
//   \ \  \\\  \  ___   \|____|\  \   ___       \ \  \|\__\_\  \   \ \  \\\  \   \ \  \    \ \  \   \ \  \_|\ \   \ \  \\ \  \   \|____|\  \        \ \  \\\  \   \ \  \___|  \ \  \_|\ \   \ \  \\ \  \
//    \ \_______\|\__\    ____\_\  \ |\__\       \ \____________\   \ \_______\   \ \__\    \ \__\   \ \_______\   \ \__\\ \__\    ____\_\  \        \ \_______\   \ \__\      \ \_______\   \ \__\\ \__\
//     \|_______|\|__|   |\_________\\|__|        \|____________|    \|_______|    \|__|     \|__|    \|_______|    \|__| \|__|   |\_________\        \|_______|    \|__|       \|_______|    \|__| \|__|
//                       \|_________|                                                                                             \|_________|

//  ________      ________      _________    ________      ________      ___           ___
// |\   __  \    |\   __  \    |\___   ___\ |\   __  \    |\   __  \    |\  \         |\  \
// \ \  \|\  \   \ \  \|\  \   \|___ \  \_| \ \  \|\ /_   \ \  \|\  \   \ \  \        \ \  \
//  \ \   __  \   \ \   _  _\       \ \  \   \ \   __  \   \ \   __  \   \ \  \        \ \  \
//   \ \  \ \  \   \ \  \\  \|       \ \  \   \ \  \|\  \   \ \  \ \  \   \ \  \____    \ \  \____
//    \ \__\ \__\   \ \__\\ _\        \ \__\   \ \_______\   \ \__\ \__\   \ \_______\   \ \_______\
//     \|__|\|__|    \|__|\|__|        \|__|    \|_______|    \|__|\|__|    \|_______|    \|_______|

// RIW & Pellar 2023

contract US_GA_Token is Ownable2Step, ERC721, VRFConsumerBase, DefaultOperatorFilterer {
  using ECDSA for bytes32;

  enum SaleType {
    Private,
    Public
  }

  struct Configs {
    SaleType saleType; // 0: private, 1: public
    uint16 quantity;
    uint16 maxPerTxn;
    uint16 maxPerWallet;
    uint32 startTime;
    uint32 endTime;
    uint120 price;
  }

  struct Phase {
    bool inited;
    Configs configs;
    uint16 version;
    uint16 totalMinted;
    mapping(address => uint16) minted;
  }

  bool public revealed;
  bool public enableTokenURI;
  bool public enableBackupURI;
  bool public enableHtmlURI;
  address public verifier = 0x730Ebaae1B58311383366E660F704834c43aa36D;
  uint256 public seedNumber;
  uint16 public boundary = 3010;
  uint256 public currIdx = 3010;
  string public preRevealedURI;
  string public baseURI;
  string public backupURI;
  string public htmlURI;
  mapping(uint16 => uint16) public randoms;
  mapping(uint256 => string) public token2URI;
  mapping(uint256 => Phase) public phases;

  event PhaseModified(uint256 indexed phaseId, Configs configs);

  constructor() ERC721("2023 U.S. Women\u2019s Open ArtBall", "USGA") VRFConsumerBase(0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, 0x514910771AF9Ca656af840dff83E8264EcF986CA) {
    preRevealedURI = "ipfs://Qmb6g3MtQvLqUrERPCu6dvbeJquQVNVybGRymMUBCANzeG";
  }

  function mintTo(address _to, uint16 _amount) public payable {
    uint256 phaseId = 4;
    require(phases[phaseId].configs.saleType == SaleType.Public, "Not available");
    require(_amount > 0, "Invalid amount");
    _mint(phaseId, _to, _amount, 1, 0, bytes(""));
  }

  function mint(uint256 _phaseId, uint16 _amount, uint16 _allocation, uint120 _unitPrice, bytes calldata _proof) public payable {
    address account = msg.sender;

    _mint(_phaseId, account, _amount, _allocation, _unitPrice, _proof);
  }

  function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
    uint256 vrfFee = 2 * (10 ** 18);
    require(LINK.balanceOf(address(this)) >= vrfFee, "Not enough LINK.");
    return requestRandomness(0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445, vrfFee);
  }

  /* View */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Non exist token");

    if (!revealed) {
      return preRevealedURI;
    }
    if (bytes(token2URI[_tokenId]).length > 0 && enableTokenURI) {
      return token2URI[_tokenId];
    }
    if (enableBackupURI) {
      return string(abi.encodePacked(backupURI, Strings.toString(_tokenId)));
    }
    if (enableHtmlURI) {
      return string(abi.encodePacked(htmlURI, Strings.toString(_tokenId)));
    }
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
  }

  function getPhaseInfo(uint256 _phaseId) external view returns (bool inited, Configs memory configs, uint16 version, uint16 totalMinted) {
    Phase storage phase = phases[_phaseId];
    return (phase.inited, phase.configs, phase.version, phase.totalMinted);
  }

  function getTokenMintedByAccount(uint256 _phaseId, address _account) external view returns (uint16) {
    return phases[_phaseId].minted[_account];
  }

  function createMintingPhase(uint256 _phaseId, Configs calldata _configs) external onlyOwner {
    require(!phases[_phaseId].inited, "Already inited");
    _validateMintingPhase(_configs);

    phases[_phaseId].inited = true;
    phases[_phaseId].configs = _configs;

    emit PhaseModified(_phaseId, _configs);
  }

  function updateMintingPhase(uint256 _phaseId, Configs calldata _configs) external onlyOwner {
    require(phases[_phaseId].inited, "Not inited");
    _validateMintingPhase(_configs);

    phases[_phaseId].configs = _configs;
    phases[_phaseId].version++;

    emit PhaseModified(_phaseId, _configs);
  }

  function updateVersion(uint256 _phaseId) external onlyOwner {
    require(phases[_phaseId].inited, "Not inited");
    phases[_phaseId].version++;

    emit PhaseModified(_phaseId, phases[_phaseId].configs);
  }

  function setVerifier(address _verifier) external onlyOwner {
    verifier = _verifier;
  }

  function toggleTokenURI(bool _status) external onlyOwner {
    enableTokenURI = _status;
  }

  function toggleBackupURI(bool _status) external onlyOwner {
    enableBackupURI = _status;
  }

  function toggleHtmlURI(bool _status) external onlyOwner {
    enableHtmlURI = _status;
  }

  function toggleReveal(bool _status) external onlyOwner {
    revealed = _status;
  }

  function setPreRevealedURI(string calldata _uri) external onlyOwner {
    preRevealedURI = _uri;
  }

  function setBaseURI(string calldata _uri) external onlyOwner {
    baseURI = _uri;
  }

  function setBackupURI(string calldata _uri) external onlyOwner {
    backupURI = _uri;
  }

  function setHtmlURI(string calldata _uri) external onlyOwner {
    htmlURI = _uri;
  }

  function setTokensURI(uint16[] calldata _tokenIds, string[] calldata _uris) external onlyOwner {
    require(_tokenIds.length == _uris.length, "Input mismatch");
    for (uint16 i = 0; i < _tokenIds.length; i++) {
      token2URI[_tokenIds[i]] = _uris[i];
    }
  }

  function mintTeam(address _to, uint256 _amount) external onlyOwner {
    require(_amount > 0, "Invalid amount");
    for (uint256 i = 0; i < _amount; i++) {
      _mint(_to, currIdx + i);
    }
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
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

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function _verifyProof(uint256 _phaseId, address _account, uint16 _allocation, uint120 _unitPrice, bytes memory _proof) private view {
    bytes32 messageHash = keccak256(abi.encodePacked(block.chainid, keccak256(abi.encode(_phaseId, phases[_phaseId].version, _account, _allocation, _unitPrice))));
    address signer = messageHash.toEthSignedMessageHash().recover(_proof);
    require(verifier == signer, "Invalid proof");
  }

  function _mintToken(address _account) private {
    uint16 index = uint16(uint256(keccak256(abi.encodePacked(seedNumber, boundary, block.timestamp, _account))) % boundary) + 1; // 1 -> 3010
    uint16 tokenId = randoms[index] > 0 ? randoms[index] : index;
    randoms[index] = randoms[boundary] > 0 ? randoms[boundary] : boundary;
    boundary = boundary - 1;

    _mint(_account, tokenId);
  }

  function _mint(uint256 _phaseId, address _account, uint16 _amount, uint16 _allocation, uint120 _unitPrice, bytes memory _proof) private {
    Phase storage phase = phases[_phaseId];
    require(phase.inited, "Not inited");
    require(phase.configs.quantity >= phase.totalMinted + _amount, "Exceed quantity");
    require(phase.configs.startTime <= block.timestamp, "Not started");
    require(phase.configs.endTime >= block.timestamp, "Ended");
    require(phase.configs.maxPerTxn >= _amount, "Exceed max per txn");
    if (phase.configs.saleType == SaleType.Private) {
      require(_allocation >= phase.minted[_account] + _amount, "Exceed max per wallet");
      require(_unitPrice * _amount <= msg.value, "Invalid price");
      _verifyProof(_phaseId, _account, _allocation, _unitPrice, _proof);
    }
    if (phase.configs.saleType == SaleType.Public) {
      require(phase.configs.maxPerWallet >= phase.minted[_account] + _amount, "Exceed max per wallet");
      require(phase.configs.price * _amount <= msg.value, "Invalid price");
    }

    for (uint256 i = 0; i < _amount; i++) {
      _mintToken(_account);
    }

    phase.totalMinted += _amount;
    phase.minted[_account] += _amount;
  }

  function _validateMintingPhase(Configs calldata _configs) private pure {
    require(_configs.quantity > 0, "Invalid quantity");
    require(_configs.maxPerTxn > 0, "Invalid max per txn");
    require(_configs.startTime > 0, "Invalid start time");
    require(_configs.endTime > _configs.startTime, "Invalid end time");
  }

  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    seedNumber = randomness;
  }
}