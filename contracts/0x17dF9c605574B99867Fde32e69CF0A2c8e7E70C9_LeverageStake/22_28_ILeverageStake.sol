pragma solidity 0.6.12;

interface ILeverageStake {
  function getAstETHBalance() external view returns (uint256 balance);

  function getStethBalance() external view returns (uint256 balance);

  function getBalanceSheet() external view returns (uint256, uint256);

  function getLeverageInfo()
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function repayBorrow(uint256 amount) external returns (uint256);

  function batchIncreaseLever(
    uint256 collateral,
    uint256 leverage,
    uint16 referralCode,
    bool isTrade
  ) external;

  function batchDecreaseLever(uint256 startAmount) external;

  function increaseLever(
    uint256 amount,
    uint16 referralCode,
    bool isTrade
  ) external returns (uint256);

  function decreaseLever(uint256 amount) external returns (uint256, bool);

  function convertToAstEth(bool isTrade) external;

  function convertToWeth() external;
}