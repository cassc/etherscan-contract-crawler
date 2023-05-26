// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error AddressAlreadyMinted();
error ProofInvalidOrNotInAllowlist();
error PublicMintingDisabled();
error AllowlistMintingDisabled();
error NotEnoughEth();
error TransferFailed();
error InvalidTreasury();
error InvalidVersion();

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPassport {
  function mintPassport(address to) external returns (uint256);
}

interface HashingModule {
  function storeTokenHash(uint256 tokenId) external;
}

interface LegacyMintingModule {
  function minted(address minter) external returns (bool);
}

contract UpgradeMintingModule is AccessControl, ReentrancyGuard {
  bytes32 public merkleRoot;
  uint256 public fee;
  uint256 public allowlistFee;
  IPassport public decagon;
  HashingModule public hashingModule;
  LegacyMintingModule public mintingModuleV1;
  LegacyMintingModule public mintingModuleV2;
  address payable public treasury;
  bool public publicMintEnabled;
  bool public allowlistMintEnabled;
  bool public oneMintPerAddress;
  mapping(address => bool) public minted;

  event PublicMintToggled();
  event AllowlistMintToggled();
  event OneMintPerAddressToggled();
  event MerkleRootSet(bytes32 indexed newMerkleRoot);
  event HashingModuleSet(address indexed newHashingModule);
  event LegacyMintingModuleSet(address indexed mintingModule);
  event PublicFeeSet(uint256 indexed newFee);
  event AllowlistFeeSet(uint256 indexed newAllowlistFee);
  event TreasuryAddressSet(address indexed newTreasuryAddress);

  // new mint event
  event DecagonMinted(uint256 indexed tokenId, address indexed minter);

  constructor(
    address decagonContractAddress,
    address _hashingModule,
    address _mintingModuleV1,
    address _mintingModuleV2,
    uint256 _fee,
    uint256 _allowlistFee,
    address payable _treasury
  ) {
    if (_treasury == address(0)) revert InvalidTreasury();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    decagon = IPassport(decagonContractAddress);
    hashingModule = HashingModule(_hashingModule);
    mintingModuleV1 = LegacyMintingModule(_mintingModuleV1);
    mintingModuleV2 = LegacyMintingModule(_mintingModuleV2);
    publicMintEnabled = false;
    allowlistMintEnabled = false;
    fee = _fee;
    allowlistFee = _allowlistFee;
    treasury = _treasury;
    oneMintPerAddress = true;
  }

  function mintDecagon() external payable nonReentrant {
    if (!publicMintEnabled) revert PublicMintingDisabled();
    if (msg.value < fee) revert NotEnoughEth();
    _mint();
  }

  function mintAllowlistedDecagon(bytes32[] calldata _merkleProof) external payable nonReentrant {
    if (!allowlistMintEnabled) revert AllowlistMintingDisabled();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert ProofInvalidOrNotInAllowlist();
    if (msg.value < allowlistFee) revert NotEnoughEth();
    _mint();
  }

  function _mint() internal {
    if (oneMintPerAddress && (minted[msg.sender] || mintingModuleV1.minted(msg.sender) || mintingModuleV2.minted(msg.sender))) revert AddressAlreadyMinted();
    minted[msg.sender] = true;

    (bool sentTreasury, ) = treasury.call{value: msg.value}("");
    if (!sentTreasury) revert TransferFailed();

    uint256 tokenId = decagon.mintPassport(msg.sender);

    emit DecagonMinted(tokenId, msg.sender);
    hashingModule.storeTokenHash(tokenId);
  }

  function setMerkleRoot(bytes32 merkleRoot_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    merkleRoot = merkleRoot_;
    emit MerkleRootSet(merkleRoot_);
  }

  function setHashingModule(address _hashingModule) external onlyRole(DEFAULT_ADMIN_ROLE) {
    hashingModule = HashingModule(_hashingModule);
    emit HashingModuleSet(_hashingModule);
  }

  function setLegacyMintingModule(address _mintingModule, uint256 _version) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_version == 1) mintingModuleV1 = LegacyMintingModule(_mintingModule);
    else if (_version == 2) mintingModuleV2 = LegacyMintingModule(_mintingModule);
    else revert InvalidVersion();
    emit LegacyMintingModuleSet(_mintingModule);
  }

  function toggleOneMintPerAddress() external onlyRole(DEFAULT_ADMIN_ROLE) {
    oneMintPerAddress = !oneMintPerAddress;
    emit OneMintPerAddressToggled();
  }

  function togglePublicMintEnabled() external onlyRole(DEFAULT_ADMIN_ROLE) {
    publicMintEnabled = !publicMintEnabled;
    emit PublicMintToggled();
  }

  function toggleAllowlistMintEnabled() external onlyRole(DEFAULT_ADMIN_ROLE) {
    allowlistMintEnabled = !allowlistMintEnabled;
    emit AllowlistMintToggled();
  }

  function setFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
    fee = newFee;
    emit PublicFeeSet(newFee);
  }

  function setAllowlistFee(uint256 newAllowlistFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
    allowlistFee = newAllowlistFee;
    emit AllowlistFeeSet(newAllowlistFee);
  }

  function setTreasury(address payable _newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_newTreasury == address(0)) revert InvalidTreasury();
    treasury = _newTreasury;
    emit TreasuryAddressSet(_newTreasury);
  }
}