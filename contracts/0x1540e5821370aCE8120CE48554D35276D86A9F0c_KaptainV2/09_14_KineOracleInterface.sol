pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/**
 * @title KineOracleInterface brief abstraction of Price Oracle
 */
interface KineOracleInterface {

    /**
     * @notice Get the underlying collateral price of given kToken.
     * @dev Returned kToken underlying price is scaled by 1e(36 - underlying token decimals)
     */
    function getUnderlyingPrice(address kToken) external view returns (uint);

    /**
     * @notice Post prices of tokens owned by Kine.
     * @param messages Signed price data of tokens
     * @param signatures Signatures used to recover reporter public key
     * @param symbols Token symbols
     */
    function postPrices(bytes[] calldata messages, bytes[] calldata signatures, string[] calldata symbols) external;

    /**
     * @notice Post Kine MCD price.
     */
    function postMcdPrice(uint mcdPrice) external;

    /**
     * @notice Get the reporter address.
     */
    function reporter() external returns (address);
}