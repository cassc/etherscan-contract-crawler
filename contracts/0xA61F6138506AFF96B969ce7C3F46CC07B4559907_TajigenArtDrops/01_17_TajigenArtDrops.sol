// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import '@openzeppelin/contracts/utils/structs/BitMaps.sol';

contract TajigenArtDrops is ERC1155URIStorage, Ownable {
  event Lock(uint256 indexed tokenId);

  using BitMaps for BitMaps.BitMap;

  mapping(uint256 => BitMaps.BitMap) _usedNonces;
  mapping(uint256 => bool) _locked;
  address _signerAddress;

  constructor() ERC1155('') {}

  function mint(
    address to,
    uint256 tokenId,
    uint256 amount,
    uint256 nonce,
    bytes calldata signature
  ) external {
    require(!_locked[tokenId], 'Mint locked');
    require(!_usedNonces[tokenId].get(nonce), 'Nonce already used');
    require(_validateSignature(to, tokenId, amount, nonce, signature), 'Invalid signature');

    _usedNonces[tokenId].set(nonce);
    _mint(to, tokenId, amount, '');
  }

  function burn(
    address from,
    uint256 tokenId,
    uint256 amount
  ) external {
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      'ERC1155: caller is not token owner or approved'
    );

    _burn(from, tokenId, amount);
  }

  function adminMint(
    address to,
    uint256 tokenId,
    uint256 amount
  ) external onlyOwner {
    require(!_locked[tokenId], 'Mint locked');

    _mint(to, tokenId, amount, '');
  }

  function nonceUsed(uint256 tokenId, uint256 nonce) external view returns (bool) {
    return _usedNonces[tokenId].get(nonce);
  }

  function locked(uint256 tokenId) external view returns (bool) {
    return _locked[tokenId];
  }

  // lock future mints
  function lock(uint256 tokenId) external onlyOwner {
    _locked[tokenId] = true;
    emit Lock(tokenId);
  }

  function setSignerAddress(address signerAddress) external onlyOwner {
    _signerAddress = signerAddress;
  }

  // default uri with {id} substitution
  function setURI(string memory uri) external onlyOwner {
    _setURI(uri);
  }

  function setURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
    _setURI(tokenId, tokenURI);
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _setBaseURI(baseURI);
  }

  function _validateSignature(
    address to,
    uint256 tokenId,
    uint256 amount,
    uint256 nonce,
    bytes calldata signature
  ) internal view virtual returns (bool) {
    bytes32 dataHash = keccak256(abi.encodePacked(tokenId, amount, nonce, to));
    bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

    return SignatureChecker.isValidSignatureNow(_signerAddress, message, signature);
  }
}