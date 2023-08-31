// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./IVault.sol";

struct Tariff {
  uint256 chainId;
  address user;
  address baseToken;
  address quoteToken;
  uint256 minBaseAmount;
  uint256 maxBaseAmount;
  uint256 minQuoteAmount;
  uint256 maxQuoteAmount;
  uint256 thresholdBaseAmount;
  uint256 thresholdQuoteAmount;
  uint256 stakingPeriod;
  uint256 yield;
  uint256 expireAt;
}

interface IRouter {
  event DualCreated(
    address indexed user,
    uint256 chainId,
    address baseToken,
    address quoteToken,
    address inputToken,
    uint256 inputAmount,
    uint256 stakingPeriod,
    uint256 yield
  );

  event DualClaimed(
    address indexed user,
    address indexed receiver,
    address outputToken,
    uint256 outputAmount,
    bytes32 txHash
  );

  event DualCanceled(address indexed user, address inputToken, uint256 inputAmount, bytes32 txHash);

  event VaultUpdated(IVault indexed oldVault, IVault indexed newVault);

  struct Input {
    address user;
    address token;
    uint256 amount;
  }

  function create(Tariff calldata tariff, Input calldata input, bytes memory signature) external;

  function createWithPermit(
    Tariff calldata tariff,
    Input calldata input,
    bytes memory signature,
    Permit calldata permit
  ) external;

  function createETH(Tariff memory tariff, bytes memory signature) external payable;

  function claim(
    address user,
    address receiver,
    address outputToken,
    uint256 outputAmount,
    bytes32 txHash,
    bytes memory signature
  ) external;

  function cancel(address user, address inputToken, uint256 inputAmount, bytes32 txHash) external;

  function updateVault(IVault) external;
}