// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "../interfaces/ILiquidityPool.sol";

interface IPCAPool {

  event PoolUpdated(address newPool);
  
  ///@notice Allows an address to deposit for itself or on behalf of another address
  ///@dev Mints pAsset at 1:1 ratio of asset deposited
  ///@dev Sends assets deposited to Tokemak pool contract
  ///@dev Can be paused
  ///@param account Account to be deposited for
  ///@param amount Amount of asset to be deposited
  function depositAsset(address account, uint256 amount) external;

  ///@notice Allows an address to deposit Tokemak tAsset for itself or on behalf of another address
  ///@dev Mints pAsset at 1:1 ratio
  ///@dev Burns tAssets via controlledBurn() function in Tokemak reactor pool
  ///@dev Can be paused
  ///@param account Account to be deposited for
  ///@param amount Amount of asset to be deposited
  function depositPoolAsset(address account, uint256 amount) external;

  ///@notice Allows for updating of tokemak reactor pool
  ///@dev old pool and new pool must have matching underlying tokens
  ///@dev Restriced access - onlyOwner
  ///@param newPool New pool to be registered
  function updatePool(ILiquidityPool newPool) external;

  ///@notice Allows some pool functionalities to be paused
  ///@dev Burn, deposit functionalities are currently pausable
  function pause() external;

  ///@notice Allows some pool functionalities to be unpaused
  function unpause() external;
}