// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract StakingPool is Ownable, IERC721Receiver, ReentrancyGuard {
  event Stake(address indexed owner, uint256 indexed tokenId);
  event Unstake(address indexed owner, uint256 indexed tokenId);

  IERC721 public tokenContract;

  mapping(address => uint16[]) private _staked;

  constructor(address tokenAddress) {
    tokenContract = IERC721(tokenAddress);
  }

  function stakedTokens(address owner)
    external
    view
    returns (uint256[] memory)
  {
    uint16[] memory staked = _staked[owner];
    uint256 numTokens = staked.length;

    uint256[] memory tokenIds = new uint256[](numTokens);
    for (uint256 i; i < numTokens; ++i) {
      tokenIds[i] = staked[i];
    }

    return tokenIds;
  }

  function stake(uint256 tokenId) external nonReentrant {
    tokenContract.safeTransferFrom(_msgSender(), address(this), tokenId);
  }

  function batchStake(uint256[] calldata tokenIds) external nonReentrant {
    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      tokenContract.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
    }
  }

  function _stake(uint256 tokenId, address owner) internal {
    _beforeStake(tokenId, owner);

    _staked[owner].push(uint16(tokenId));
    emit Stake(owner, tokenId);
  }

  function _beforeStake(uint256 tokenId, address owner) internal virtual {}

  function unstake(uint256 tokenId) external nonReentrant {
    _unstake(tokenId, _msgSender());
  }

  function batchUnstake(uint256[] calldata tokenIds) external nonReentrant {
    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      _unstake(tokenIds[i], _msgSender());
    }
  }

  function unstakeAll() external nonReentrant {
    _unstakeAll(_msgSender());
  }

  function _unstakeAll(address owner) internal {
    uint256 stakedCount = _staked[owner].length;
    for (uint256 i = stakedCount; i > 0; --i) {
      _unstakeIndex(i - 1, owner);
    }
  }

  function _unstake(uint256 tokenId, address owner) internal {
    uint256 stakedCount = _staked[owner].length;
    for (uint256 i; i < stakedCount; ++i) {
      if (_staked[owner][i] == tokenId) {
        _unstakeIndex(i, owner);
        break;
      }
    }
  }

  function unstakeIndex(uint256 index) external nonReentrant {
    _unstakeIndex(index, _msgSender());
  }

  function batchUnstakeIndex(uint256[] memory indices) external nonReentrant {
    _sort(indices, _staked[_msgSender()].length);

    // iterate in reverse order
    for (uint256 i = indices.length; i > 0; --i) {
      _unstakeIndex(indices[i - 1], _msgSender());
    }
  }

  function batchUnstakeIndexSorted(uint256[] memory indices)
    external
    nonReentrant
  {
    // iterate in reverse order
    uint256 lastIndex = type(uint256).max;
    for (uint256 i = indices.length; i > 0; --i) {
      uint256 index = indices[i - 1];
      if (index < lastIndex) {
        lastIndex = index;
        _unstakeIndex(index, _msgSender());
      }
    }
  }

  function _unstakeIndex(uint256 index, address owner) internal {
    uint16 tokenId = _staked[owner][index];
    _beforeUnstake(tokenId, owner);

    uint256 lastIndex = _staked[owner].length - 1;
    if (index != lastIndex) {
      _staked[owner][index] = _staked[owner][lastIndex]; // swap with last item
    }
    _staked[owner].pop();

    tokenContract.safeTransferFrom(address(this), owner, tokenId);
    emit Unstake(owner, tokenId);
  }

  function _beforeUnstake(uint256 tokenId, address owner) internal virtual {}

  function forceUnstake(address owner) external onlyOwner {
    _unstakeAll(owner);
  }

  // unique counting sort
  function _sort(uint256[] memory data, uint256 setSize) internal pure {
    uint256 length = data.length;
    bool[] memory set = new bool[](setSize);
    for (uint256 i = 0; i < length; ++i) {
      set[data[i]] = true;
    }
    uint256 n = 0;
    for (uint256 i = 0; i < setSize; ++i) {
      if (set[i]) {
        data[n] = i;
        if (++n >= length) break;
      }
    }
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _staked[owner].length;
  }

  function onERC721Received(
    address,
    address from,
    uint256 tokenId,
    bytes memory data
  ) public virtual override returns (bytes4) {
    require(_msgSender() == address(tokenContract), 'Unknown token contract');

    address owner = data.length > 0 ? abi.decode(data, (address)) : from;
    _stake(tokenId, owner);
    return this.onERC721Received.selector;
  }
}