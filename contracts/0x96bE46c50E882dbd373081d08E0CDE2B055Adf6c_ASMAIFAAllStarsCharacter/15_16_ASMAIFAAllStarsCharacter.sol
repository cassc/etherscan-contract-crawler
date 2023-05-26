// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import './WhitelistTimelock.sol';

contract ASMAIFAAllStarsCharacter is ERC721Enumerable, WhitelistTimelock {
  using ECDSA for bytes32;
  using Address for address;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  address private _signer;
  bool public isFreezeAllowed;

  mapping(uint256 => string) public tokenHashes;
  mapping(uint256 => bool) public isFrozen;
  mapping(uint256 => bool) public isConfigured;
  mapping(uint256 => bool) public reservedTokenIds;

  uint256[4] public specialTokenIds = [2384, 12384, 22384, 23840];

  event Minted(address minter, address recipient, string hash, uint256 tokenId);
  event Configured(address minter, string hash, uint256 tokenId);
  event PermanentURI(string _value, uint256 indexed _id);
  event HashUpdated(string hash, uint256 tokenId);
  event FreezeAllowed(bool allowed);

  constructor(address signer)
    ERC721('ASMAIFAAllStarsCharacter', 'AIFACharacter')
  {
    require(signer != address(0), 'Signer should not be a zero address.');
    _signer = signer;

    for (uint256 i = 0; i < specialTokenIds.length; i++) {
      reservedTokenIds[specialTokenIds[i]] = true;
    }
  }

  function _hash(
    string memory hash,
    uint256 reservedAt,
    uint256 expiryMillis,
    uint256 tokenId
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(tokenId, hash, reservedAt, expiryMillis));
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

  function _nextItemId() internal returns (uint256) {
    while (reservedTokenIds[_tokenIds.current()]) {
      _tokenIds.increment();
    }
    return _tokenIds.current();
  }

  function mint(string[4] calldata hashes, address recipient)
    external
    onlyWhitelisted
  {
    for (uint256 i = 0; i < hashes.length; i++) {
      uint256 newItemId = _nextItemId();
      _safeMint(recipient, newItemId);
      _tokenIds.increment();

      tokenHashes[newItemId] = hashes[i];

      emit Minted(msg.sender, recipient, hashes[i], newItemId);
    }
  }

  function mintSpecial(string[4] calldata hashes, address recipient)
    external
    onlyWhitelisted
  {
    for (uint256 i = 0; i < hashes.length; i++) {
      uint256 newItemId = specialTokenIds[i];
      _safeMint(recipient, newItemId);

      tokenHashes[newItemId] = hashes[i];

      emit Minted(msg.sender, recipient, hashes[i], newItemId);
    }
  }

  function freeze(uint256 tokenId) external {
    require(isFreezeAllowed, 'Freezing is not allowed for now.');
    require(ownerOf(tokenId) == msg.sender, 'Permission denied.');
    isFrozen[tokenId] = true;

    // https://docs.opensea.io/docs/metadata-standards#section-freezing-metadata
    // indicate to OpenSea that metadata is no longer changeable by anyone
    emit PermanentURI(tokenURI(tokenId), tokenId);
  }

  function configure(
    string calldata hash,
    bytes calldata signature,
    uint256 reservedAt,
    uint256 expiryMillis,
    uint256 tokenId
  ) external {
    require(ownerOf(tokenId) == msg.sender, 'Permission denied.');
    require(
      block.timestamp * 1000 <= reservedAt + expiryMillis,
      'Configuration expired.'
    );
    require(!isFrozen[tokenId], 'Character is fronzen.');
    require(!isConfigured[tokenId], 'Character can only be configured once.');
    require(
      _verify(_hash(hash, reservedAt, expiryMillis, tokenId), signature),
      'Invalid signature.'
    );

    tokenHashes[tokenId] = hash;
    isConfigured[tokenId] = true;

    emit Configured(msg.sender, hash, tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'URI query for nonexistent token');

    string memory hash = tokenHashes[tokenId];
    return
      bytes(hash).length > 0 ? string(abi.encodePacked('ipfs://', hash)) : '';
  }

  function updateHash(string calldata hash, uint256 tokenId)
    external
    onlyWhitelisted
  {
    require(
      getApproved(tokenId) == msg.sender ||
        isApprovedForAll(ownerOf(tokenId), msg.sender),
      'The operator must be approved by token owner.'
    );

    tokenHashes[tokenId] = hash;

    emit HashUpdated(hash, tokenId);
  }

  function setFreezeAllowed(bool allowed) external onlyWhitelisted {
    isFreezeAllowed = allowed;
    emit FreezeAllowed(allowed);
  }
}