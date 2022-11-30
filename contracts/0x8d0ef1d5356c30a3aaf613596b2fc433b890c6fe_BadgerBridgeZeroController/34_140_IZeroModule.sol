// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IZeroModule {
  function repayLoan(
    address _to,
    address _asset,
    uint256 _actualAmount,
    uint256 _amount,
    bytes memory _data
  ) external;

  function receiveLoan(
    address _to,
    address _asset,
    uint256 _actual,
    uint256 _nonce,
    bytes memory _data
  ) external;

  function computeReserveRequirement(uint256 _in) external view returns (uint256);

  function want() external view returns (address);
}