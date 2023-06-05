// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './WhitelistTimelock.sol';

interface IBox {
  function ownerOf(uint256 tokenId) external view returns (address);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface IBrain {
  function mint(string calldata hash, address recipient) external;
}

interface ICharacter {
  function mint(string[4] calldata hashes, address recipient) external;

  function mintSpecial(string[4] calldata hashes, address recipient) external;
}

contract ASMAIFAAllStarsUnbox is WhitelistTimelock, ReentrancyGuard {
  using ECDSA for bytes32;
  using Strings for uint256;

  address private _signer;
  address public boxContract;
  address public brainContract;
  address public characterContract;
  uint256 public specialBoxId;

  address public constant BURN_ADDRESS =
    address(0x000000000000000000000000000000000000dEaD);

  mapping(uint256 => bool) public isOpened;
  bool public isOpenAllowed;

  struct UnboxingContentHash {
    string brain;
    string character1;
    string character2;
    string character3;
    string character4;
  }

  event BoxOpened(address operator, uint256 boxTokenId);
  event OpenAllowed(bool allowed);
  event BrainContractSet(address _contract);
  event CharacterContractSet(address _contract);

  constructor(
    address signer,
    address _boxContract,
    address _brainContract,
    address _characterContract,
    uint256 _specialBoxId
  ) {
    require(signer != address(0), 'Signer should not be a zero address.');
    _signer = signer;
    boxContract = _boxContract;
    brainContract = _brainContract;
    characterContract = _characterContract;
    specialBoxId = _specialBoxId;
  }

  function _hash(UnboxingContentHash calldata hash, uint256 boxTokenId)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          hash.brain,
          hash.character1,
          hash.character2,
          hash.character3,
          hash.character4,
          boxTokenId
        )
      );
  }

  function _verify(bytes32 hash, bytes memory token)
    internal
    view
    returns (bool)
  {
    return (_recover(hash, token) == _signer);
  }

  function _recover(bytes32 hash, bytes memory token)
    internal
    pure
    returns (address)
  {
    return hash.toEthSignedMessageHash().recover(token);
  }

  function openBox(
    UnboxingContentHash calldata hash,
    bytes calldata signature,
    uint256 boxTokenId
  ) external nonReentrant {
    require(isOpenAllowed, 'Box is not allowed to open.');
    require(!isOpened[boxTokenId], 'Box already opened.');
    require(
      IBox(boxContract).ownerOf(boxTokenId) == msg.sender,
      'Box can only be openned by the owner.'
    );
    require(_verify(_hash(hash, boxTokenId), signature), 'Invalid signature.');

    IBrain(brainContract).mint(hash.brain, msg.sender);

    if (boxTokenId == specialBoxId) {
      ICharacter(characterContract).mintSpecial(
        [hash.character1, hash.character2, hash.character3, hash.character4],
        msg.sender
      );
    } else {
      ICharacter(characterContract).mint(
        [hash.character1, hash.character2, hash.character3, hash.character4],
        msg.sender
      );
    }

    IBox(boxContract).transferFrom(msg.sender, BURN_ADDRESS, boxTokenId);

    isOpened[boxTokenId] = true;

    emit BoxOpened(msg.sender, boxTokenId);
  }

  function setOpenAllowed(bool allowed) external onlyWhitelisted {
    isOpenAllowed = allowed;
    emit OpenAllowed(allowed);
  }

  function setBrainContract(address _contract) external onlyWhitelisted {
    brainContract = _contract;
    emit BrainContractSet(_contract);
  }

  function setCharacterContract(address _contract) external onlyWhitelisted {
    characterContract = _contract;
    emit CharacterContractSet(_contract);
  }
}