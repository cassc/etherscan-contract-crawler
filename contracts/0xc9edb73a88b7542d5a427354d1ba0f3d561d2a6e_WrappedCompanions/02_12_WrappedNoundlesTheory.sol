// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface INoundlesTheory is IERC721 {
  function noundleType(uint256 tokenId) external view returns (uint8);

  function noundleOffsetCount(uint256 tokenId) external view returns (uint256);
}

contract WrappedNoundlesTheory is ERC721, Ownable {
  using Strings for uint256;

  INoundlesTheory public immutable tokenContract;

  address public stakingPool;

  uint8 private immutable _noundleType;
  uint256 private _mintCount;
  string private _baseTokenURI;

  constructor(
    string memory name,
    string memory symbol,
    uint8 noundleType,
    address tokenAddress
  ) ERC721(name, symbol) {
    _noundleType = noundleType;
    tokenContract = INoundlesTheory(tokenAddress);
  }

  function wrap(uint256 tokenId, bool stake) external {
    address owner = tokenContract.ownerOf(tokenId);
    require(owner != address(this), 'Token already wrapped');

    _wrap(tokenId, owner, stake);
  }

  function batchWrap(uint256[] calldata tokenIds, bool stake) external {
    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      address owner = tokenContract.ownerOf(tokenIds[i]);
      if (owner != address(this)) {
        _wrap(tokenIds[i], owner, stake);
      }
    }
  }

  function _wrap(
    uint256 tokenId,
    address owner,
    bool stake
  ) internal {
    require(
      tokenContract.noundleType(tokenId) == _noundleType,
      'Incorrect token type'
    );
    tokenContract.transferFrom(owner, address(this), tokenId);

    uint256 newTokenId = tokenContract.noundleOffsetCount(tokenId);

    _mintCount++;
    if (stake) {
      require(stakingPool != address(0), 'Staking pool not configured');
      _safeMint(stakingPool, newTokenId, abi.encode(owner));
    } else {
      _safeMint(owner, newTokenId);
    }
  }

  function unwrap(uint256 tokenId, uint256 originalTokenId) external {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: transfer caller is not owner nor approved'
    );

    _unwrap(tokenId, originalTokenId);
  }

  function batchUnwrap(
    uint256[] calldata tokenIds,
    uint256[] calldata originalTokenIds
  ) external {
    require(
      tokenIds.length == originalTokenIds.length,
      'Invalid token amounts'
    );
    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      if (_isApprovedOrOwner(_msgSender(), tokenIds[i])) {
        _unwrap(tokenIds[i], originalTokenIds[i]);
      }
    }
  }

  function _unwrap(uint256 tokenId, uint256 originalTokenId) internal {
    require(
      tokenContract.noundleType(originalTokenId) == _noundleType,
      'Incorrect token type'
    );
    require(
      tokenId == tokenContract.noundleOffsetCount(originalTokenId),
      'Mismatched token id'
    );

    address owner = ERC721.ownerOf(tokenId);
    _burn(tokenId);

    _mintCount--;
    tokenContract.transferFrom(address(this), owner, originalTokenId);
  }

  function totalSupply() external view returns (uint256) {
    return _mintCount;
  }

  function walletOfOwner(address owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 balance = balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](balance);

    uint256 offset;
    for (uint256 i = 0; offset < balance; ++i) {
      if (_exists(i) && ownerOf(i) == owner) {
        tokenIds[offset] = i;
        ++offset;
      }
    }

    return tokenIds;
  }

  function setStakingPool(address contractAddress) external onlyOwner {
    stakingPool = contractAddress;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    _baseTokenURI = newBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }
}