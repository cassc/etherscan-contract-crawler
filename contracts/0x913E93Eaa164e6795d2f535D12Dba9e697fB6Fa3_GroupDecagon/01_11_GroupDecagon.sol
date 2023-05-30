// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./GroupErrors.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IPassport {
  function mintPassport(address to) external returns (uint256);
}

interface ITokenHashes {
  function storeTokenHash(uint256 tokenId) external;
}

interface IColourHashes {
  function storeColourHash(uint256 tokenId, bytes32 colourHash) external;
}

contract GroupDecagon is AccessControl, ReentrancyGuard {
  event GroupMintToggled();
  event OnePerGroupToggled();
  event SignerSet(address indexed newSigner);
  event MaxFriendsSet(uint256 indexed newMaxFriends);
  event TokenHashesSet(address indexed newTokenHashes);
  event GroupFeeSet(uint256 indexed newFee);
  event TreasuryAddressSet(address indexed newTreasuryAddress);
  event ColourHashesSet(address indexed newIColourHashesAddress);
  event GroupMinted(
    address[] friends,
    uint256[] ids,
    bytes32 indexed colourHash
  );

  uint256 public fee;

  uint256 public maxFriends;

  address public signerAddress;

  address payable public treasury;

  IPassport public decagon;

  ITokenHashes public tokenHashes;

  IColourHashes public colourHashes;

  bool public groupMintEnabled;

  bool public onePerGroupEnabled;

  mapping(bytes32 => bool) public minted;

  mapping(bytes => bool) public usedSignature;

  constructor(
    uint256 _fee,
    address payable _treasury,
    address _decagon,
    address _tokenHashes,
    address _colourHashes,
    address _signerAddress
  ) {
    if (
      _treasury == address(0) ||
      _decagon == address(0) ||
      _tokenHashes == address(0) ||
      _colourHashes == address(0) ||
      _signerAddress == address(0)
    ) revert AddressNotSet();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    fee = _fee;
    treasury = _treasury;
    decagon = IPassport(_decagon);
    tokenHashes = ITokenHashes(_tokenHashes);
    colourHashes = IColourHashes(_colourHashes);
    signerAddress = _signerAddress;
    maxFriends = 2;
    groupMintEnabled = false;
    onePerGroupEnabled = false;
  }

  function generateGroupHash(
    address[] memory _friends
  ) public pure returns (bytes32 groupHash) {
    groupHash = keccak256(abi.encode(_friends));
  }

  function generateColourHash(
    address[] memory _address,
    uint256 _tokenId1
  ) public pure returns (bytes32 colourHash) {
    colourHash = keccak256(abi.encode(_address, _tokenId1));
  }

  function toggleGroupMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
    groupMintEnabled = !groupMintEnabled;
    emit GroupMintToggled();
  }

  function toggleOnePerGroup() external onlyRole(DEFAULT_ADMIN_ROLE) {
    onePerGroupEnabled = !onePerGroupEnabled;
    emit OnePerGroupToggled();
  }

  function setFee(uint256 _newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
    fee = _newFee;
    emit GroupFeeSet(_newFee);
  }

  function setMaxFriends(
    uint256 _newMaxFriends
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxFriends = _newMaxFriends;
    emit MaxFriendsSet(_newMaxFriends);
  }

  function setTokenHashes(
    address _newTokenHashesAddress
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_newTokenHashesAddress == address(0)) revert AddressNotSet();
    tokenHashes = ITokenHashes(_newTokenHashesAddress);
    emit TokenHashesSet(_newTokenHashesAddress);
  }

  function setColourHashes(
    address _newColourHashesAddress
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_newColourHashesAddress == address(0)) revert AddressNotSet();
    colourHashes = IColourHashes(_newColourHashesAddress);
    emit ColourHashesSet(_newColourHashesAddress);
  }

  function setTreasury(
    address payable _newTreasury
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_newTreasury == address(0)) revert AddressNotSet();
    treasury = _newTreasury;
    emit TreasuryAddressSet(_newTreasury);
  }

  function setSigner(
    address _signerAddress
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_signerAddress == address(0)) revert AddressNotSet();
    signerAddress = _signerAddress;
    emit SignerSet(_signerAddress);
  }

  function mintGroup(
    address[] calldata _friends,
    uint256 _expiryBlock,
    bytes calldata _signature
  ) external payable nonReentrant returns (uint256[] memory ids) {
    if (!groupMintEnabled) revert GroupMintingDisabled();
    if (usedSignature[_signature]) revert SignatureAlreadyUsed();
    bytes32 groupHash = generateGroupHash(_friends);
    if (onePerGroupEnabled && minted[groupHash]) revert GroupHashAlreadyUsed();
    uint256 numberOfFriends = _friends.length;
    if (numberOfFriends < 2) revert NoFriends();
    if (numberOfFriends > maxFriends) revert ExceedsMaxFriends();
    if (block.number > _expiryBlock) revert ExpiredSignature();
    if (msg.value < (fee * numberOfFriends)) revert NotEnoughEth();
    if (
      !verify(
        keccak256(
          abi.encodePacked(msg.sender, _friends, _expiryBlock, address(this))
        ),
        _signature
      )
    ) revert InvalidSignature();
    usedSignature[_signature] = true;
    minted[groupHash] = true;
    ids = _mint(_friends);
    (bool sentTreasury, ) = treasury.call{value: msg.value}("");
    if (!sentTreasury) revert TransferFailed();
  }

  function _mint(
    address[] memory _friends
  ) internal returns (uint256[] memory) {
    uint256[] memory ids = new uint256[](_friends.length);
    ids[0] = decagon.mintPassport(_friends[0]);
    bytes32 colourHash = generateColourHash(_friends, ids[0]);
    colourHashes.storeColourHash(ids[0], colourHash);
    tokenHashes.storeTokenHash(ids[0]);
    for (uint256 i = 1; i < _friends.length; i++) {
      ids[i] = decagon.mintPassport(_friends[i]);
      colourHashes.storeColourHash(ids[i], colourHash);
      tokenHashes.storeTokenHash(ids[i]);
    }
    emit GroupMinted(_friends, ids, colourHash);
    return ids;
  }

  function verify(
    bytes32 messageHash,
    bytes memory signature
  ) internal view returns (bool) {
    return
      signerAddress ==
      ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), signature);
  }
}