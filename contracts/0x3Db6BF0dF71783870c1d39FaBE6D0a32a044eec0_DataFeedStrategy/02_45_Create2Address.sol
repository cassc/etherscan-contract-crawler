//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.8 <0.9.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library Create2Address {
  /// @notice Deterministically computes the pool address given the factory, salt and initCodeHash
  /// @param _factory The Uniswap V3 factory contract address
  /// @param _salt The PoolKey encoded bytes
  /// @param _initCodeHash The Init Code Hash of the target
  /// @return _pool The contract address of the target pool/oracle
  function computeAddress(
    address _factory,
    bytes32 _salt,
    bytes32 _initCodeHash
  ) internal pure returns (address _pool) {
    _pool = address(uint160(uint256(keccak256(abi.encodePacked(hex'ff', _factory, _salt, _initCodeHash)))));
  }
}