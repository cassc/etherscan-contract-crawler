// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ILiquidity {
  event AddedToWhitelist(address indexed _address);
  event RemovedFromWhitelist(address indexed _address);
  event Withdrawn(address indexed _token, uint256 _amount, address indexed _to);
  event Received(address indexed _from, uint256 _amount);
  event PositionChanged(
    uint256 indexed positionId,
    uint256 amount0,
    uint256 amount1,
    uint256 liquidity,
    int24 tickLower,
    int24 tickUpper
  );

  function balanceOfToken0() external view returns (uint256);

  function balanceOfToken1() external view returns (uint256);

  function setFeeAddress(address _address) external;

  function withdraw(address _token, uint256 _amount, address payable _to) external;

  function closePosition() external;

  function changePosition(int24 tickLower, int24 tickUpper, uint256 withdrawToken0Amount, uint256 withdrawToken1Amount, address payable withdrawToken0Destination, address payable withdrawToken1Destination) external;

  function makeEmergencyCall(address contractToCall, bytes calldata callData) external;
}