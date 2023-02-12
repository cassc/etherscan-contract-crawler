// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {SignatureChecker} from '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import {BitMaps} from '@openzeppelin/contracts/utils/structs/BitMaps.sol';

import {ERC165} from './ERC165.sol';

import {IERC721Metadata} from './interfaces/ERC721Metadata.sol';
import {IERC4973} from './interfaces/ERC4973.sol';

bytes32 constant AGREEMENT_HASH = keccak256('Agreement(address active,address passive)');

/// @notice Modified version of the reference implementation of EIP-4973 tokens.
/// @author Felix Nordén
/// Heavy inspiration taken from the reference implementation (https://github.com/rugpullindex/ERC4973/blob/master/src/ERC4973.sol)
abstract contract ERC4973O is EIP712, ERC165, IERC721Metadata, IERC4973 {
  using BitMaps for BitMaps.BitMap;
  BitMaps.BitMap internal _usedHashes;

  string private _name;
  string private _symbol;

  mapping(uint256 => address) private _owners;
  mapping(address => uint256) private _balances;

  constructor(string memory name_, string memory symbol_, string memory version) EIP712(name_, version) {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IERC721Metadata).interfaceId || interfaceId == type(IERC4973).interfaceId || super.supportsInterface(interfaceId);
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function unequip(uint256 tokenId) public virtual override {
    require(msg.sender == ownerOf(tokenId), 'unequip: sender must be owner');
    _usedHashes.unset(tokenId);
    _burn(tokenId);
  }

  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), 'balanceOf: address zero is not a valid owner');
    return _balances[owner];
  }

  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ownerOf: token doesn't exist");
    return owner;
  }

  function _give(address to, bytes calldata signature) internal virtual returns (uint256) {
    require(msg.sender != to, "_give: can't give from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, to, signature);
    require(!_usedHashes.get(tokenId), '_give: id already used');
    _mint(msg.sender, to, tokenId);
    _usedHashes.set(tokenId);
    return tokenId;
  }

  function _take(address from, bytes calldata signature) internal virtual returns (uint256) {
    require(msg.sender != from, "_take: can't take from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, from, signature);
    require(!_usedHashes.get(tokenId), '_take: id already used');
    _mint(from, msg.sender, tokenId);
    _usedHashes.set(tokenId);
    return tokenId;
  }

  function _safeCheckAgreement(address active, address passive, bytes calldata signature) internal virtual returns (uint256) {
    bytes32 hash = _getHash(active, passive);
    require(SignatureChecker.isValidSignatureNow(passive, hash, signature), '_safeCheckAgreement: invalid signature');

    uint256 tokenId = uint256(hash);
    return tokenId;
  }

  function _getHash(address active, address passive) internal view returns (bytes32) {
    bytes32 structHash = keccak256(abi.encode(AGREEMENT_HASH, active, passive));

    return _hashTypedDataV4(structHash);
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _mint(address from, address to, uint256 tokenId) internal virtual returns (uint256) {
    require(!_exists(tokenId), '_mint: tokenId exists');
    _balances[to] += 1;
    _owners[tokenId] = to;
    emit Transfer(from, to, tokenId);
    return tokenId;
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);

    _balances[owner] -= 1;
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }
}