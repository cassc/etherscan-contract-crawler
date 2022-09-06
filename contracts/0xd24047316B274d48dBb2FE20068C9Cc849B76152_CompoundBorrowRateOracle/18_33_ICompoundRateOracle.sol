// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "../compound/ICToken.sol";
import "./IRateOracle.sol";

interface ICompoundRateOracle is IRateOracle {

    /// @notice Gets the address of the cToken
    /// @return Address of the cToken
    function ctoken() external view returns (ICToken);

    /// @notice Gets the number of decimals of the underlying
    /// @return Number of decimals of the underlying
    function decimals() external view returns (uint8);

}