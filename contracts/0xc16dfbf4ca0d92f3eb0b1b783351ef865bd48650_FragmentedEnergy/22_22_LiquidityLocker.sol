// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';

contract LiquidityLocker is Ownable {
  using SafeERC20 for IERC20;

  uint256 public deployed;
  uint256 public lockedSpan;

  INonfungiblePositionManager _v3Manager;

  constructor(INonfungiblePositionManager __v3Manager) {
    deployed = block.timestamp;
    _v3Manager = __v3Manager;
  }

  function collectV3Fees(uint256 _lpId) external onlyOwner {
    _v3Manager.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: _lpId,
        recipient: owner(),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );
  }

  function unlockV2Liquidity(address _pool) external onlyOwner {
    require(block.timestamp > liquidityUnlocked());
    IERC20(_pool).safeTransfer(owner(), IERC20(_pool).balanceOf(address(this)));
  }

  function unlockV3Liquidity(uint256 _lpId) external onlyOwner {
    require(block.timestamp > liquidityUnlocked());
    _v3Manager.transferFrom(address(this), owner(), _lpId);
  }

  function addToLockedTime(uint256 _addSeconds) external onlyOwner {
    lockedSpan += _addSeconds;
  }

  function liquidityUnlocked() public view returns (uint256) {
    return deployed + lockedSpan;
  }
}