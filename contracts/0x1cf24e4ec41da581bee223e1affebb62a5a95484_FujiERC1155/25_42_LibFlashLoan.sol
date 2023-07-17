// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.5;

library FlashLoan {
  /**
  * @dev Used to determine which vault's function to call post-flashloan:
  * - Switch for executeSwitch(...)
  * - Close for executeFlashClose(...)
  * - Liquidate for executeFlashLiquidation(...)
  */
  enum CallType { Switch, Close, Liquidate }

  /**
  * @dev Struct of params to be passed between functions executing flashloan logic
  * @param asset: Address of asset to be borrowed with flashloan
  * @param amount: Amount of asset to be borrowed with flashloan
  * @param vault: Vault's address on which the flashloan logic to be executed
  * @param newProvider: New provider's address. Used when callType is Switch
  * @param user: User's address. Used when callType is Close or Liquidate
  * @param userliquidator: The user's address who is  performing liquidation. Used when callType is Liquidate
  * @param fliquidator: Fujis Liquidator's address.
  */
  struct Info {
    CallType callType;
    address asset;
    uint256 amount;
    address vault;
    address newProvider;
    address user;
    address userliquidator;
    address fliquidator;
  }
}