// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../libraries/InputBuilding.sol';
import '../libraries/SecondsUntilNextSwap.sol';
import '../interfaces/IDCAHubCompanion.sol';

abstract contract DCAHubCompanionLibrariesHandler is IDCAHubCompanionLibrariesHandler {
  /// @inheritdoc IDCAHubCompanionLibrariesHandler
  function getNextSwapInfo(
    IDCAHub _hub,
    Pair[] calldata _pairs,
    bool _calculatePrivilegedAvailability,
    bytes calldata _oracleData
  ) external view returns (IDCAHub.SwapInfo memory) {
    (address[] memory _tokens, IDCAHub.PairIndexes[] memory _indexes) = InputBuilding.buildGetNextSwapInfoInput(_pairs);
    return _hub.getNextSwapInfo(_tokens, _indexes, _calculatePrivilegedAvailability, _oracleData);
  }

  /// @inheritdoc IDCAHubCompanionLibrariesHandler
  function legacyGetNextSwapInfo(ILegacyDCAHub _hub, Pair[] calldata _pairs) external view returns (ILegacyDCAHub.SwapInfo memory) {
    (address[] memory _tokens, IDCAHub.PairIndexes[] memory _indexes) = InputBuilding.buildGetNextSwapInfoInput(_pairs);
    return _hub.getNextSwapInfo(_tokens, _indexes);
  }

  /// @inheritdoc IDCAHubCompanionLibrariesHandler
  function secondsUntilNextSwap(
    IDCAHub _hub,
    Pair[] calldata _pairs,
    bool _calculatePrivilegedAvailability
  ) external view returns (uint256[] memory) {
    return SecondsUntilNextSwap.secondsUntilNextSwap(_hub, _pairs, _calculatePrivilegedAvailability);
  }
}