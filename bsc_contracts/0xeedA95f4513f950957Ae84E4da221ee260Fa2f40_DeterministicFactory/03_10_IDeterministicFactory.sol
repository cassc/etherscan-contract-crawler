// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @title Interface for using the DeterministicFactory
/// @notice These methods allow users or developers to interact with CREATE3 library from solmate
interface IDeterministicFactory {
  /// @notice Hash of admin role
  /// @return The keccak of ADMIN_ROLE
  function ADMIN_ROLE() external view returns (bytes32);

  /// @notice Hash of deployer role
  /// @return The keccak of DEPLOYER_ROLE
  function DEPLOYER_ROLE() external view returns (bytes32);

  /// @notice Deploy to deterministic addresses without an initcode factor
  /// @param _salt Random salt that will help contract's address generation
  /// @param _creationCode Smart contract creation code (including constructor args)
  /// @param _value Amount of ETH to sent on deployment
  /// @return _deployed The deterministic address of the deployed smart contract
  function deploy(
    bytes32 _salt,
    bytes memory _creationCode,
    uint256 _value
  ) external payable returns (address _deployed);

  /// @notice Get deployed address by salt
  /// @param _salt Random salt that will help contract's address generation
  /// @return The deterministic address of the deployed smart contract
  function getDeployed(bytes32 _salt) external view returns (address);
}