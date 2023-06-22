// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IHegicPoolProtocolParameters {
  event MinTokenReservesSet(uint256 minTokenReserves);
  event WithdrawCooldownSet(uint256 withdrawCooldown);
  event WidthawFeeSet(uint256 withdrawFee);
  function setMinTokenReserves(uint256 minTokenReserves) external;
  function setWithdrawCooldown(uint256 withdrawCooldown) external;
  function setWithdrawFee(uint256 withdrawFee) external;
}