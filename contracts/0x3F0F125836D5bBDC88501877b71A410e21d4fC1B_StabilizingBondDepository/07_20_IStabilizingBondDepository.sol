// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBondDepositoryCommon.sol";

interface IStabilizingBondDepository is IBondDepositoryCommon {
  function purchase(
    uint256 amount,
    uint256 maxPrice,
    uint256 minOutput,
    address recipient
  ) external returns (uint256 bondId);

  function updateOracles() external;

  function updatedBondPrice() external returns (uint256 price);

  function updatedReward() external returns (uint256 reward);

  function getReward(uint256 degree) external view returns (uint256 reward);

  function getCurrentReward() external view returns (uint256);

  function getTwapDeviationFromPrice(uint256 oraclePrice)
    external
    view
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    );

  function getTwapDeviation()
    external
    view
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    );

  function getSpotDeviationFromPrice(uint256 oraclePrice)
    external
    view
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    );

  function getSpotDeviation()
    external
    view
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    );

  function bondPriceFromDeviation(uint256 deviation)
    external
    view
    returns (uint256 price);

  function setTolerance(uint256 _tolerance) external;

  function setMaxRewardFactor(uint256 _maxRewardFactor) external;

  function setControlVariable(uint256 _controlVariable) external;

  function setBluTwapOracle(address _bluTwapOracle) external;

  function setStablecoinTwapOracle(address _stablecoinTwapOracle) external;

  function setStablecoinOracle(address _stablecoinOracle) external;

  event UpdatedTolerance(uint256 _tolerance);
  event UpdatedMaxRewardFactor(uint256 _maxRewardFactor);
  event UpdatedControlVariable(uint256 _controlVariable);
  event UpdatedBluTwapOracle(address indexed _oracle);
  event UpdatedStablecoinTwapOracle(address indexed _oracle);
  event UpdatedStablecoinOracle(address indexed _oracle);
  event RedeemPaused(bool indexed _paused);
  event PurchasePaused(bool indexed _paused);
}