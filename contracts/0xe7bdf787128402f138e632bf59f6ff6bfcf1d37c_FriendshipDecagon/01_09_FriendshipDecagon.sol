// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error FriendshipAlreadyExists();
error FriendshipMintingDisabled();
error NotEnoughEth();
error TransferFailed();
error AddressNotSet();
error CannotMintFriendshipWithSelf();

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPassport {
  function mintPassport(address to) external returns (uint256);
}

interface ITokenHashes {
  function storeTokenHash(uint256 tokenId) external;
}

interface IColourHashes {
  function storeColourHash(uint256 tokenId, bytes32 colourHash) external;
}

contract FriendshipDecagon is AccessControl, ReentrancyGuard {
  event FriendshipMintToggled();
  event OneMintPerFriendshipToggled();
  event TokenHashesSet(address indexed newTokenHashes);
  event FriendshipFeeSet(uint256 indexed newFee);
  event TreasuryAddressSet(address indexed newTreasuryAddress);
  event ColourHashesSet(address indexed newIColourHashesAddress);
  event FriendshipMinted(
    address friend1,
    uint256 indexed tokenId1,
    address friend2,
    uint256 indexed tokenId2,
    bytes32 indexed colourHash
  );

  uint256 public fee;

  address payable public treasury;

  IPassport public decagon;

  ITokenHashes public tokenHashes;

  IColourHashes public colourHashes;

  bool public friendshipMintEnabled;

  bool public oneMintPerFriendship;

  mapping(bytes32 => bool) public minted;

  constructor(
    uint256 _fee,
    address payable _treasuryAddress,
    address _decagonAddress,
    address _tokenHashesAddress,
    address _colourHashesAddress
  ) {
    if (
      _treasuryAddress == address(0) ||
      _decagonAddress == address(0) ||
      _tokenHashesAddress == address(0) ||
      _colourHashesAddress == address(0)
    ) revert AddressNotSet();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    fee = _fee;
    treasury = _treasuryAddress;
    decagon = IPassport(_decagonAddress);
    tokenHashes = ITokenHashes(_tokenHashesAddress);
    colourHashes = IColourHashes(_colourHashesAddress);
    friendshipMintEnabled = false;
    oneMintPerFriendship = true;
  }

  function generateFriendshipHash(address _address1, address _address2)
    public
    pure
    returns (bytes32 friendshipHash)
  {
    if (_address1 < _address2) {
      friendshipHash = keccak256(abi.encodePacked(_address1, _address2));
    } else {
      friendshipHash = keccak256(abi.encodePacked(_address2, _address1));
    }
  }

  function generateColourHash(
    address _address1,
    uint256 _tokenId1,
    address _address2,
    uint256 _tokenId2
  ) public pure returns (bytes32 colourHash) {
    if ((_address1 < _address2) && (_tokenId1 < _tokenId2)) {
      colourHash = keccak256(
        abi.encodePacked(_address1, _tokenId1, _address2, _tokenId2)
      );
    }
    if ((_address1 < _address2) && (_tokenId2 < _tokenId1)) {
      colourHash = keccak256(
        abi.encodePacked(_address1, _tokenId2, _address2, _tokenId1)
      );
    }
    if ((_address2 < _address1) && (_tokenId1 < _tokenId2)) {
      colourHash = keccak256(
        abi.encodePacked(_address2, _tokenId1, _address1, _tokenId2)
      );
    }
    if ((_address2 < _address1) && (_tokenId2 < _tokenId1)) {
      colourHash = keccak256(
        abi.encodePacked(_address2, _tokenId2, _address1, _tokenId1)
      );
    }
  }

  function toggleFriendshipMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
    friendshipMintEnabled = !friendshipMintEnabled;
    emit FriendshipMintToggled();
  }

  function toggleOneMintPerFriendship() external onlyRole(DEFAULT_ADMIN_ROLE) {
    oneMintPerFriendship = !oneMintPerFriendship;
    emit OneMintPerFriendshipToggled();
  }

  function setFee(uint256 _newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
    fee = _newFee;
    emit FriendshipFeeSet(_newFee);
  }

  function setTokenHashes(address _newTokenHashesAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (_newTokenHashesAddress == address(0)) revert AddressNotSet();
    tokenHashes = ITokenHashes(_newTokenHashesAddress);
    emit TokenHashesSet(_newTokenHashesAddress);
  }

  function setColourHashes(address _newColourHashesAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (_newColourHashesAddress == address(0)) revert AddressNotSet();
    colourHashes = IColourHashes(_newColourHashesAddress);
    emit ColourHashesSet(_newColourHashesAddress);
  }

  function setTreasury(address payable _newTreasury)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (_newTreasury == address(0)) revert AddressNotSet();
    treasury = _newTreasury;
    emit TreasuryAddressSet(_newTreasury);
  }

  function mintFriendshipDecagon(address _friend)
    external
    payable
    nonReentrant
    returns (uint256 tokenId1, uint256 tokenId2)
  {
    if (!friendshipMintEnabled) revert FriendshipMintingDisabled();
    if (msg.value < fee) revert NotEnoughEth();
    (tokenId1, tokenId2) = _mint(_friend);
    (bool sentTreasury, ) = treasury.call{value: msg.value}("");
    if (!sentTreasury) revert TransferFailed();
  }

  function _mint(address _friend)
    internal
    returns (uint256 tokenId1, uint256 tokenId2)
  {
    if (msg.sender == _friend) revert CannotMintFriendshipWithSelf();
    bytes32 friendshipHash = generateFriendshipHash(msg.sender, _friend);
    if (minted[friendshipHash] && oneMintPerFriendship)
      revert FriendshipAlreadyExists();
    minted[friendshipHash] = true;

    tokenId1 = decagon.mintPassport(msg.sender);
    tokenId2 = decagon.mintPassport(_friend);

    bytes32 colourHash = generateColourHash(
      msg.sender,
      tokenId1,
      _friend,
      tokenId2
    );

    emit FriendshipMinted(msg.sender, tokenId1, _friend, tokenId2, colourHash);

    colourHashes.storeColourHash(tokenId1, colourHash);
    colourHashes.storeColourHash(tokenId2, colourHash);

    tokenHashes.storeTokenHash(tokenId1);
    tokenHashes.storeTokenHash(tokenId2);
  }
}