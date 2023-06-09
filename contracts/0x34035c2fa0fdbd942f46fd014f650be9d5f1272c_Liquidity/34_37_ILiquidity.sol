// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Interface for Liquidity contract
interface ILiquidity {
  /// @dev Emitted when an address is added to the whitelist
  event AddedToWhitelist(address indexed _address);
  /// @dev Emitted when an address is removed from the whitelist
  event RemovedFromWhitelist(address indexed _address);
  /// @dev Emitted when tokens are withdrawn from the contract
  event Withdrawn(address indexed _token, uint256 _amount, address indexed _to);
  /// @dev Emitted when ETH is received by the contract
  event Received(address indexed _from, uint256 _amount);
  /// @dev Emitted when collect earnings
  event Earned(uint256 amount0, uint256 amount1);
  /// @dev Emitted when the position is changed
  event PositionChanged(
    uint256 indexed positionId,
    uint256 amount0,
    uint256 amount1,
    uint256 liquidity,
    int24 tickLower,
    int24 tickUpper,
    uint256 timestamp
  );

  /// @notice Get the balance of token0 held by the contract
  /// @return The balance of token0
  function balanceOfToken0() external view returns (uint256);

  /// @notice Get the balance of token1 held by the contract
  /// @return The balance of token1
  function balanceOfToken1() external view returns (uint256);

  /// @notice Set the fee address for the contract
  /// @param _feeAddress The address to set as the fee address
  function setFeeAddress(address _feeAddress) external;

  /// @notice Withdraw tokens from the contract
  /// @param _token The token to withdraw
  /// @param _amount The amount to withdraw
  /// @param _to The address to send the withdrawn tokens
  function withdraw(address _token, uint256 _amount, address payable _to) external;

  /// @notice Close the current position
  function closePosition() external;

  /// @notice Change the position of the contract
  /// @param tickLower The new lower tick
  /// @param tickUpper The new upper tick
  /// @param withdrawToken0Destination The address to send the withdrawn token0
  /// @param withdrawToken1Destination The address to send the withdrawn token1
  /// @return the token id of new position
  function changePosition(
    int24 tickLower,
    int24 tickUpper,
    address payable withdrawToken0Destination,
    address payable withdrawToken1Destination
  ) external returns (uint256);

  /// @notice Make an emergency call to another contract
  /// @param contractToCall The address of the contract to call
  /// @param callData The calldata to use for the call
  function makeEmergencyCall(address contractToCall, bytes calldata callData) external;

  /// @dev Show info about current position
  /// @return positionId The position ID of the current position
  /// @return tickLower The tickLower of the current position
  /// @return tickUpper The tickUpper of the current position
  /// @return reserve0 The reserve in token0 of the current position
  /// @return reserve1 The reserve in token1 of the current position
  function getPositionInfo() external returns (uint256, int24, int24, uint256, uint256);
}