// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AggregatorValidatorInterface.sol";

contract TestValidator is AggregatorValidatorInterface {
  uint32 s_minGasUse;
  uint256 s_latestRoundId;

  event Validated(
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer,
    uint256 initialGas
  );

  function validate(
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer
  ) external override returns (bool) {
    uint256 initialGas = gasleft();

    emit Validated(
      previousRoundId,
      previousAnswer,
      currentRoundId,
      currentAnswer,
      initialGas
    );
    s_latestRoundId = currentRoundId;

    uint256 minGasUse = s_minGasUse;
    while (initialGas - gasleft() < minGasUse) {}

    return true;
  }

  function setMinGasUse(uint32 minGasUse) external {
    s_minGasUse = minGasUse;
  }

  function latestRoundId() external view returns (uint256) {
    return s_latestRoundId;
  }
}