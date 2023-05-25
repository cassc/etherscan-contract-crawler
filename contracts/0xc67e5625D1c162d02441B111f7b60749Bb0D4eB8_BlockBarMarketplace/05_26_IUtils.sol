// SPDX-License-Identifier:  AGPL-3.0-or-later
pragma solidity 0.8.18;


/**
 * @title IUtils
 * @author aarora
 * @notice IUtils contains all external function interfaces and events
 */
interface IUtils {

    /**
     * @notice Utility for getting the bytes value of USD. Used for creating a listing.
     *
     * @return USDCurrency bytes32
     */
    function getUSDCurrencyBytes() external pure returns (bytes32 USDCurrency);

    /**
     * @notice Utility for getting the bytes value of ETH. Used for creating a listing.
     *
     * @return ETHCurrency bytes32
     */
    function getETHCurrencyBytes() external pure returns (bytes32 ETHCurrency);

    /**
     * @notice Utility for retrieving ETH Price in USD from Chainlink oracle.
     *
     * @return ETHPriceInUSD Price of 1 ETH in USD
     */
    function getETHPriceInUSD() external view returns (uint256 ETHPriceInUSD);

    /**
     * @notice Utility for converting USD cents padded by 1e18 (Wei representation) to ETH Wei.
     *
     * @param amountInUSD USD value in cents padded by 1e18 (Wei representation).
     *
     * @return ETHWei ETH Value in Wei of USD cents value padded by 1e18
     */
    function convertUSDWeiToETHWei(uint256 amountInUSD) external view returns(uint256 ETHWei);

    /**
     * @notice Utility for converting ETH Wei to USD cents padded by 1e18 (Wei representation).
     *
     * @param amountInETH ETH value in Wei.
     *
     * @return USDWei USD cents padded by 1e18 value of ETH Wei
     */
    function convertETHWeiToUSDWei(uint256 amountInETH) external view returns(uint256 USDWei);

    /**
     * @notice Utility for comparing two values and determining whether they are close (based on the threshold %).
     *
     * @param originalAmount  Value to be considered the truth value.
     * @param compareToAmount Value to be tested. If this value is not within the threshold of the original value,
                              the function will return false.
     * @param threshold       Threshold for how close the above values need to be.
     *
     * @return valueIsClose boolean indicating whether two numbers are close or not.
     */
    function isClose(
        uint256 originalAmount,
        uint256 compareToAmount,
        uint256 threshold
    ) external pure returns (bool valueIsClose);
}