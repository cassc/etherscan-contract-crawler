// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Interface for Liquidity contract
interface ILiquidity {
  /// @dev Emitted when ETH is received by the contract
  event Received(address indexed _from, uint256 _amount);

  /// @notice Get the balance of token0 held by the contract
  /// @return The balance of token0
  function balanceOfToken0() external view returns (uint256);

  /// @notice Get the balance of token1 held by the contract
  /// @return The balance of token1
  function balanceOfToken1() external view returns (uint256);

  /// @notice Withdraw tokens from the contract
  /// @param _token The token to withdraw
  /// @param _amount The amount to withdraw
  /// @param _to The address to send the withdrawn tokens
  function withdraw(address _token, uint256 _amount, address payable _to) external;

  /// @notice Close the current position
  function closePosition() external;

  /// @notice Change the position of the contract
  /// @param _tickLower The new lower tick
  /// @param _tickUpper The new upper tick
  /// @param sqrtPriceAX96 The new sqrtPriceAX96
  /// @param sqrtPriceBX96 The new sqrtPriceBX96
  /// @param withdrawToken0Destination The address to send the withdrawn token0
  /// @param withdrawToken1Destination The address to send the withdrawn token1
  function changePosition(
    int24 _tickLower,
    int24 _tickUpper,
    uint160 sqrtPriceAX96,
    uint160 sqrtPriceBX96,
    address payable withdrawToken0Destination,
    address payable withdrawToken1Destination
  ) external;

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
  function getPositionInfo() external returns (uint256, int24, int24, uint256, uint256, uint128);
}