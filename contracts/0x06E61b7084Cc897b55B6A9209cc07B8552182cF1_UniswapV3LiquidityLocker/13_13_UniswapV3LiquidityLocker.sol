// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';

contract UniswapV3LiquidityLocker is Ownable {
  INonfungiblePositionManager immutable _positions;
  uint256 public created;
  uint256 public lockedTime;

  constructor() {
    _positions = INonfungiblePositionManager(
      0xC36442b4a4522E871399CD717aBDD847Ab11FE88
    );
    created = block.timestamp;
  }

  function unlockedAt() public view returns (uint256) {
    return created + lockedTime;
  }

  function collectFees(uint256 _tokenId) external onlyOwner {
    _positions.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: _tokenId,
        recipient: owner(),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );
  }

  function unlock(uint256 _tokenId) external onlyOwner {
    require(block.timestamp > unlockedAt());
    _positions.transferFrom(address(this), owner(), _tokenId);
  }

  function extendLock(uint256 _extraSeconds) external onlyOwner {
    lockedTime += _extraSeconds;
  }
}