// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IRegistry.sol";
import "./IFee.sol";

interface IRegistryCore is IRegistry {
  struct SignedBalance {
    int128 balance;
    uint32 lastUpdate;
  }

  struct AccruedFee {
    int128 fundingFee;
    uint128 rolloverFee;
    uint32 lastUpdate;
  }

  struct OnOrderUpdate {
    IRegistryCore.SignedBalance feeBalance;
    int128 feeBase;
    IRegistryCore.AccruedFee accruedFee;
  }

  function getOpenFee(address _user) external view returns (IFee.Fee memory);

  function getCloseFee(address _user) external view returns (IFee.Fee memory);

  function getAccumulatedFee(
    bytes32 orderHash,
    uint64 closePercent
  ) external view returns (int128, uint128);

  function onOrderUpdate(
    bytes32 orderHash
  ) external view returns (OnOrderUpdate memory);

  function updateTrade(
    bytes32 orderHash,
    uint128 oraclePrice,
    uint128 margin,
    bool isAdding
  ) external view returns (Trade memory);

  function updateStop(
    bytes32 orderHash,
    uint128 oraclePrice,
    uint128 profitTarget,
    uint128 stopLoss
  ) external view returns (Trade memory);

  function maxTotalLongPerPriceId(
    bytes32 priceId
  ) external view returns (uint128);

  function maxTotalShortPerPriceId(
    bytes32 priceId
  ) external view returns (uint128);
}