// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IAladdinSdCRVExtension {
  /// @notice Deposit sdveCRV into the contract.
  /// @dev Use `_assets=uint256(-1)` if you want to deposit all sdveCRV.
  /// @param _assets The amount of sdveCRV to desposit.
  /// @param _receiver The address of account who will receive the pool share.
  /// @return _shares The amount of pool shares received.
  function depositWithSdVeCRV(uint256 _assets, address _receiver) external returns (uint256 _shares);

  /// @notice Deposit CRV into the contract.
  /// @dev Use `_assets=uint256(-1)` if you want to deposit all CRV.
  /// @param _assets The amount of CRV to desposit.
  /// @param _receiver The address of account who will receive the pool share.
  /// @param _minShareOut The minimum amount of share to receive.
  /// @return _shares The amount of pool shares received.
  function depositWithCRV(
    uint256 _assets,
    address _receiver,
    uint256 _minShareOut
  ) external returns (uint256 _shares);
}