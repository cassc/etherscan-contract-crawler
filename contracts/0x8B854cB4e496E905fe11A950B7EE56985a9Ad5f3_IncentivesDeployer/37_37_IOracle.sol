//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title An interface for interacting with oracles such as Chainlink, Uniswap V2/V3 TWAP, Band etc.
/// @notice This interface allows fetching prices for two tokens.
interface IOracle {
    /// @notice Address of the first token this oracle adapter supports.
    function token0() external view returns (address);

    /// @notice Address of the second token this oracle adapter supports.
    function token1() external view returns (address);

    /// @notice Returns the price of a supported token, relatively to the other token.
    function getPrice(address _token) external view returns (int256);
}