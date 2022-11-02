// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ICurveGauge {
  function deposit(uint256 _value) external;

  function integrate_fraction(address arg0) external view returns (uint256);

  function balanceOf(address arg0) external view returns (uint256);

  function claimable_tokens(address arg0) external returns (uint256);

  function withdraw(uint256 _value) external;

  /// @dev The address of the LP token that may be deposited into the gauge.
  function lp_token() external view returns (address);

  function user_checkpoint(address _user) external returns (bool);
}