// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

/**
 * @dev ProtocolFactory contract interface. See {ProtocolFactory}.
 * @author [email protected]
 */
interface IProtocolFactory {
  /// @notice emit when a new protocol is supported in COVER
  event ProtocolInitiation(address protocolAddress);

  function getAllProtocolAddresses() external view returns (address[] memory);
  function getRedeemFees() external view returns (uint16 _numerator, uint16 _denominator);
  function redeemFeeNumerator() external view returns (uint16);
  function redeemFeeDenominator() external view returns (uint16);
  function protocolImplementation() external view returns (address);
  function coverImplementation() external view returns (address);
  function coverERC20Implementation() external view returns (address);
  function treasury() external view returns (address);
  function governance() external view returns (address);
  function claimManager() external view returns (address);
  function protocols(bytes32 _protocolName) external view returns (address);

  function getProtocolsLength() external view returns (uint256);
  function getProtocolNameAndAddress(uint256 _index) external view returns (bytes32, address);
  /// @notice return contract address, the contract may not be deployed yet
  function getProtocolAddress(bytes32 _name) external view returns (address);
  /// @notice return contract address, the contract may not be deployed yet
  function getCoverAddress(bytes32 _protocolName, uint48 _timestamp, address _collateral, uint256 _claimNonce) external view returns (address);
  /// @notice return contract address, the contract may not be deployed yet
  function getCovTokenAddress(bytes32 _protocolName, uint48 _timestamp, address _collateral, uint256 _claimNonce, bool _isClaimCovToken) external view returns (address);

  /// @notice access restriction - owner (dev)
  /// @dev update this will only affect contracts deployed after
  function updateProtocolImplementation(address _newImplementation) external returns (bool);
  /// @dev update this will only affect contracts deployed after
  function updateCoverImplementation(address _newImplementation) external returns (bool);
  /// @dev update this will only affect contracts deployed after
  function updateCoverERC20Implementation(address _newImplementation) external returns (bool);
  function assignClaimManager(address _address) external returns (bool);
  function addProtocol(
    bytes32 _name,
    bool _active,
    address _collateral,
    uint48[] calldata _timestamps,
    bytes32[] calldata _timestampNames
  ) external returns (address);

  /// @notice access restriction - governance
  function updateClaimManager(address _address) external returns (bool);
  function updateFees(uint16 _redeemFeeNumerator, uint16 _redeemFeeDenominator) external returns (bool);
  function updateGovernance(address _address) external returns (bool);
  function updateTreasury(address _address) external returns (bool);
}