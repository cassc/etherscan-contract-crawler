// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library FiduConversions {
  uint256 internal constant FIDU_MANTISSA = 1e18;
  uint256 internal constant USDC_MANTISSA = 1e6;
  uint256 internal constant USDC_TO_FIDU_MANTISSA = FIDU_MANTISSA / USDC_MANTISSA;
  uint256 internal constant FIDU_USDC_CONVERSION_DECIMALS = USDC_TO_FIDU_MANTISSA * FIDU_MANTISSA;

  /**
   * @notice Convert Usdc to Fidu using a given share price
   * @param usdcAmount amount of usdc to convert
   * @param sharePrice share price to use to convert
   * @return fiduAmount converted fidu amount
   */
  function usdcToFidu(uint256 usdcAmount, uint256 sharePrice) internal pure returns (uint256) {
    return sharePrice > 0 ? (usdcAmount * FIDU_USDC_CONVERSION_DECIMALS) / sharePrice : 0;
  }

  /**
   * @notice Convert fidu to USDC using a given share price
   * @param fiduAmount fidu amount to convert
   * @param sharePrice share price to do the conversion with
   * @return usdcReceived usdc that will be received after converting
   */
  function fiduToUsdc(uint256 fiduAmount, uint256 sharePrice) internal pure returns (uint256) {
    return (fiduAmount * sharePrice) / FIDU_USDC_CONVERSION_DECIMALS;
  }
}