// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

library FiduConversion {
  uint256 internal constant FIDU_USDC_CONVERSION_DECIMALS = 1e30;

  /**
   * @notice Convert Usdc to Fidu using a given share price
   * @param usdcAmount amount of usdc to convert
   * @param sharePrice share price to use to convert
   * @return fiduAmount converted fidu amount
   */
  function usdcToFidu(uint256 usdcAmount, uint256 sharePrice) internal pure returns (uint256) {
    return sharePrice > 0 && usdcAmount > 0
      ? (usdcAmount * FIDU_USDC_CONVERSION_DECIMALS) / sharePrice
      : 0;
  }

  /**
   * @notice Convert fidu to USDC using a given share price
   * @param fiduAmount fidu amount to convert
   * @param sharePrice share price to do the conversion with
   * @return usdcReceived usdc that will be received after converting
   */
  function fiduToUsdc(uint256 fiduAmount, uint256 sharePrice)
    internal
    pure
    returns (uint256 usdcReceived)
  {
    return fiduAmount > 0 && sharePrice > 0
      ? (fiduAmount * sharePrice) / FIDU_USDC_CONVERSION_DECIMALS
      : 0;
  }
}