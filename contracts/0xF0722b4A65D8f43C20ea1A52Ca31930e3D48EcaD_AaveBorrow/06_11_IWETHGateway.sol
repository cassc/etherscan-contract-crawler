pragma solidity ^0.8.15;

interface IWETHGateway {
  function borrowETH(
    address lendingPool,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode
  ) external;
}