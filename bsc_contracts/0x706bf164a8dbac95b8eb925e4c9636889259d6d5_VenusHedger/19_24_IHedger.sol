// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.10;

interface IHedger {
  //
  // Implemented in UpgradeableHedgerBase
  //

  function setConfig(address _config, address _augustus) external;

  function setERC20Allowance(address token, address spender, uint256 amount) external;

  function swap(bytes memory swapCalldata) external;

  function withdrawERC(address token, uint256 amount) external;

  function withdrawERCAll(address token) external;

  function approveERC(address token, address spender, uint256 amount) external;

  //
  // Implemented per Hedger
  //

  function depositCollateral(uint256 amount) external;

  function canHedge(
    address token,
    address underlying, // need this for Venus compatibility
    uint256 amount,
    uint256 buffer
  ) external view returns (bool possible, uint256 availableCollateral, uint256 shortfall);

  function canPayback(uint256 maxAmountToSwap) external view returns (bool possible, uint256 shortfall);
}