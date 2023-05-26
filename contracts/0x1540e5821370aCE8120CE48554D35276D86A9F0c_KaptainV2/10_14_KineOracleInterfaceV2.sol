pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/**
 * @title KineOracleInterface brief abstraction of Price Oracle
 */
interface KineOracleInterfaceV2 {

    /**
     * @notice Get the underlying collateral price of given kToken.
     * @dev Returned kToken underlying price is scaled by 1e(36 - underlying token decimals)
     */
    function getUnderlyingPrice(address kToken) external view returns (uint);

    /**
     * @notice Post prices of tokens.
     * @param symbols Token symbols
     * @param prices Token prices
     */
    function postPrices(string[] calldata symbols, uint[] calldata prices) external;

    /**
     * @notice Post Kine MCD price.
     */
    function postMcdPrice(uint mcdPrice) external;
}