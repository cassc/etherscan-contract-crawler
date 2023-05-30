// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/// @title Interface for an oracle of the options token's strike price
/// @author zefram.eth
/// @notice An oracle of the options token's strike price
interface IOracle {
    /// @notice Computes the current strike price of the option
    /// @return price The strike price in terms of the payment token, scaled by 18 decimals.
    /// For example, if the payment token is $2 and the strike price is $4, the return value
    /// would be 2e18.
    function getPrice() external view returns (uint256 price);
}