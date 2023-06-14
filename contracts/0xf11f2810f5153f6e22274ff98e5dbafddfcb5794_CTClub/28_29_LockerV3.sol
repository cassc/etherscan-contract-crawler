// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';

contract LockerV3 is Ownable {
  uint256 public created;
  uint256 public lockedSeconds;
  INonfungiblePositionManager public v3LPManager;

  constructor() {
    created = block.timestamp;
    v3LPManager = INonfungiblePositionManager(
      0xC36442b4a4522E871399CD717aBDD847Ab11FE88
    );
  }

  function collectFees(uint256 _id) external onlyOwner {
    v3LPManager.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: _id,
        recipient: owner(),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );
  }

  function unlock(uint256 _id) external onlyOwner {
    require(block.timestamp > created + lockedSeconds);
    v3LPManager.transferFrom(address(this), owner(), _id);
  }

  function addToLockedSeconds(uint256 _addSeconds) external onlyOwner {
    lockedSeconds += _addSeconds;
  }
}