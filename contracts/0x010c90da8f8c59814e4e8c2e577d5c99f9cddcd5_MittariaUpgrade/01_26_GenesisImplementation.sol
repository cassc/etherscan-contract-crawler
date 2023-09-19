// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// Openzepplin ERC2981
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./royalty/DefaultOperatorFiltererUpgradeable.sol";

// ::::    ::::  ::::::::::: ::::::::::: :::::::::::     :::     :::::::::  :::::::::::     :::
// +:+:+: :+:+:+     :+:         :+:         :+:       :+: :+:   :+:    :+:     :+:       :+: :+:
// +:+ +:+:+ +:+     +:+         +:+         +:+      +:+   +:+  +:+    +:+     +:+      +:+   +:+
// +#+  +:+  +#+     +#+         +#+         +#+     +#++:++#++: +#++:++#:      +#+     +#++:++#++:
// +#+       +#+     +#+         +#+         +#+     +#+     +#+ +#+    +#+     +#+     +#+     +#+
// #+#       #+#     #+#         #+#         #+#     #+#     #+# #+#    #+#     #+#     #+#     #+#
// ###       ### ###########     ###         ###     ###     ### ###    ### ########### ###     ###

// ADVENTURE, EXPLORE & DISCOVER
// Mittaria & Pellar

contract MittariaUpgrade is
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  ERC721Upgradeable,
  ERC2981Upgradeable,
  DefaultOperatorFiltererUpgradeable
{
  using ECDSAUpgradeable for bytes32;

  // struct
  struct Configs {
    uint16 quantity;
    uint16 maxPerTxn;
    uint32 startTime;
    uint32 endTime;
    uint128 price;
  }

  struct Phase {
    Configs configs;
    uint16 version;
    uint16 totalMinted;
    mapping(address => uint16) minted;
  }

  // vars
  bool public revealed;
  bool public enableTokenURI;
  bool public enableBackupURI;
  bool public enableHtmlURI;
  address public verifier;
  uint16 public currentIdx;
  uint16 public maxSupply;
  string public preRevealedURI;
  string public baseURI;
  string public backupURI;
  string public htmlURI;
  Phase[] public phases;
  mapping(uint256 => string) public token2URI;
  mapping(address => bool) public executors;

  event PhaseModified(uint256 indexed phaseId, Configs configs);

  function initialize() public initializer {
    __Ownable_init();
    __ERC721_init("Mittaria Contract", "MITT"); 
    __ERC2981_init();

    // 7.5%
    setPrimaryRoyalty(0x961E3f37Ce55799E27C1E8CeE24305fccFE7591C, 750);

    // init public phase
    phases.push();

    // init configs
    verifier = 0x9f6B54d48AD2175e56a1BA9bFc74cd077213B68D;
    currentIdx = 1;
    maxSupply = 5555;
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  modifier onlyAllowedExecutor() {
    require(executors[_msgSender()] || owner() == _msgSender(), "Not allowed operator");
    _;
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
      return string(abi.encodePacked(backupURI, StringsUpgradeable.toString(_tokenId)));
    }
    if (enableHtmlURI) {
      return string(abi.encodePacked(htmlURI, StringsUpgradeable.toString(_tokenId)));
    }
    return string(abi.encodePacked(baseURI, StringsUpgradeable.toString(_tokenId)));
  }

  // verifed
  function getPhaseInfo(uint256 _phaseId) external view returns (Configs memory configs, uint16 version, uint16 totalMinted) {
    require(_phaseId < phases.length, "Invalid phase id");
    Phase storage phase = phases[_phaseId];
    return (phase.configs, phase.version, phase.totalMinted);
  }

  // verifed
  function getTokenMintedByAccount(uint256 _phaseId, address _account) external view returns (uint16) {
    require(_phaseId < phases.length, "Invalid phase id");
    return phases[_phaseId].minted[_account];
  }

  /* User */
  // verifed
  function mint(uint256 _phaseId, uint16 _amount, uint16 _maxAmount, bytes calldata _signature) external payable {
    address account = msg.sender;
    require(tx.origin == account, "Not allowed");

    Phase storage phase = phases[_phaseId];
    require(_amount > 0, "Invalid amount");
    require(phase.configs.quantity >= phase.totalMinted + _amount, "Exceed quantity");
    require(phase.configs.startTime <= block.timestamp, "Not started");
    require(phase.configs.endTime >= block.timestamp, "Ended");
    require(phase.configs.maxPerTxn >= _amount, "Exceed max per txn");
    require(_maxAmount >= phase.minted[account] + _amount, "Exceed max per wallet");
    require(phase.configs.price * _amount == msg.value, "Invalid price");
    _verifySignature(_phaseId, account, _maxAmount, _signature);

    phase.totalMinted += _amount;
    phase.minted[account] += _amount;

    _mintToken(account, _amount);
  }

  function mintTo(address _to, uint16 _amount) external payable {
    Phase storage phase = phases[0];
    require(_amount > 0, "Invalid amount");
    require(phase.configs.quantity >= phase.totalMinted + _amount, "Exceed quantity");
    require(phase.configs.startTime <= block.timestamp, "Not started");
    require(phase.configs.endTime >= block.timestamp, "Ended");
    require(phase.configs.maxPerTxn >= _amount, "Exceed max per txn");
    require(phase.configs.price * _amount == msg.value, "Invalid price");

    phase.totalMinted += _amount;
    phase.minted[_to] += _amount;

    _mintToken(_to, _amount);
  }

  // verifed
  function _mintToken(address _account, uint16 _amount) internal {
    require(currentIdx + _amount - 1 <= maxSupply, "Exceed max supply");
    uint256 _currentIdx = currentIdx;
    currentIdx += _amount;
    for (uint256 i = 0; i < _amount; i++) {
      _mint(_account, _currentIdx + i);
    }
  }

  // verifed
  function _verifySignature(uint256 _phaseId, address _account, uint16 _maxAmount, bytes calldata _signature) internal view {
    bytes32 messageHash = keccak256(abi.encodePacked(block.chainid, keccak256(abi.encode(_phaseId, phases[_phaseId].version, _account, _maxAmount))));
    address signer = messageHash.toEthSignedMessageHash().recover(_signature);
    require(verifier == signer, "Invalid proof");
  }

  /* Admin */
  function setTotalSupply(uint16 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  // verifed
  function _validateMintingPhase(Configs calldata _configs) internal pure {
    require(_configs.quantity > 0, "Invalid quantity");
    require(_configs.maxPerTxn > 0, "Invalid max per txn");
    require(_configs.startTime > 0, "Invalid start time");
    require(_configs.endTime > _configs.startTime, "Invalid end time");
  }

  // verifed
  function createMintingPhase(Configs calldata _configs) external onlyOwner {
    _validateMintingPhase(_configs);

    uint256 phaseId = phases.length;
    phases.push();
    phases[phaseId].configs = _configs;

    emit PhaseModified(phaseId, _configs);
  }

  // verifed
  function updateMintingPhase(uint256 _phaseId, Configs calldata _configs) external onlyOwner {
    require(_phaseId < phases.length, "Invalid phase id");
    _validateMintingPhase(_configs);

    phases[_phaseId].configs = _configs;
    phases[_phaseId].version++;

    emit PhaseModified(_phaseId, _configs);
  }

  // verifed
  function setExecutor(address[] memory _executors, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _executors.length; i++) {
      executors[_executors[i]] = _status;
    }
  }

  // verifed
  function setVerifier(address _verifier) external onlyOwner {
    require(_verifier != address(0), "Invalid verifier");
    verifier = _verifier;
  }

  // verified
  function toggleTokenURI(bool _status) external onlyOwner {
    enableTokenURI = _status;
  }

  // verified
  function toggleBackupURI(bool _status) external onlyOwner {
    enableBackupURI = _status;
  }

  // verified
  function toggleHtmlURI(bool _status) external onlyOwner {
    enableHtmlURI = _status;
  }

  // verified
  function toggleReveal(bool _status) external onlyOwner {
    revealed = _status;
  }

  // verified
  function setPreRevealedURI(string calldata _uri) external onlyAllowedExecutor {
    preRevealedURI = _uri;
  }

  // verified
  function setBaseURI(string calldata _uri) external onlyAllowedExecutor {
    baseURI = _uri;
  }

  // verified
  function setBackupURI(string calldata _uri) external onlyAllowedExecutor {
    backupURI = _uri;
  }

  // verified
  function setHtmlURI(string calldata _uri) external onlyAllowedExecutor {
    htmlURI = _uri;
  }

  // verifed
  function setTokensURI(uint16[] calldata _tokenIds, string[] calldata _uris) external onlyAllowedExecutor {
    require(_tokenIds.length == _uris.length, "Input mismatch");
    for (uint16 i = 0; i < _tokenIds.length; i++) {
      token2URI[_tokenIds[i]] = _uris[i];
    }
  }

  // verifed
  function adminMintTo(address _to, uint256 _amount) external onlyOwner {
    require(_amount > 0, "Invalid amount");
    _mintToken(_to, uint16(_amount));
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /* Royalty */
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

  function setPrimaryRoyalty(address _receiver, uint96 _feeNumerator) public onlyAllowedExecutor {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  // verified
  function deleteDefaultRoyalty() public onlyAllowedExecutor {
    _deleteDefaultRoyalty();
  }

  // verified
  function setRoyaltyInfoForToken(uint256 _tokenId, address _receiver, uint96 _feeNumerator) public onlyAllowedExecutor {
    _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
  }

  // verified
  function resetRoyaltyInforToken(uint256 _tokenId) public onlyAllowedExecutor {
    _resetTokenRoyalty(_tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981Upgradeable, ERC721Upgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}