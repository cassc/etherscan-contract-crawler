// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

contract WrappedNoundles is ERC721, Ownable {
  using Strings for uint256;

  IERC721Metadata public tokenContract;

  address public stakingPool;

  uint256 private _mintCount;
  string private _baseTokenURI;

  constructor(address tokenAddress) ERC721('Wrapped Noundles', 'WNOUNDLES') {
    tokenContract = IERC721Metadata(tokenAddress);
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
    tokenContract.transferFrom(owner, address(this), tokenId);

    _mintCount++;
    if (stake) {
      require(stakingPool != address(0), 'Staking pool not configured');
      _safeMint(stakingPool, tokenId, abi.encode(owner));
    } else {
      _safeMint(owner, tokenId);
    }
  }

  function unwrap(uint256 tokenId) external {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: transfer caller is not owner nor approved'
    );

    _unwrap(tokenId);
  }

  function batchUnwrap(uint256[] calldata tokenIds) external {
    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      if (_isApprovedOrOwner(_msgSender(), tokenIds[i])) {
        _unwrap(tokenIds[i]);
      }
    }
  }

  function _unwrap(uint256 tokenId) internal {
    address owner = ERC721.ownerOf(tokenId);
    _burn(tokenId);

    _mintCount--;
    tokenContract.transferFrom(address(this), owner, tokenId);
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

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );

    return
      bytes(_baseTokenURI).length > 0
        ? string(abi.encodePacked(_baseTokenURI, tokenId.toString()))
        : tokenContract.tokenURI(tokenId);
  }
}