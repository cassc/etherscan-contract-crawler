// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IJRTSwapModule {
  /**
   * @notice executes an AMM swap from collateral to JRT
   * @param _recipient address receiving JRT tokens
   * @param _collateral address of the collateral token to swap
   * @param _jarvisToken address of the jarvis token to buy
   * @param _amountIn exact amount of collateral to swap
   * @param _params extra params needed on the specific implementation (with different AMM)
   * @return amountOut amount of JRT in output
   */
  function swapToJRT(
    address _recipient,
    address _collateral,
    address _jarvisToken,
    uint256 _amountIn,
    bytes calldata _params
  ) external returns (uint256 amountOut);
}