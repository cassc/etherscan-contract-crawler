pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface IMigratorChef {
  // Take the current LP token address and return the new LP token address.
  // Migrator should have full access to the caller's LP token.
  function migrate(IERC20 token) external returns (IERC20);
}