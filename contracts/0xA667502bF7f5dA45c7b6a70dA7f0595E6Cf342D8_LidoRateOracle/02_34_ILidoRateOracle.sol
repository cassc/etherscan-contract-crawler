// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "../lido/IStETH.sol";
import "../rate_oracles/IRateOracle.sol";
import "../lido/ILidoOracle.sol";

interface ILidoRateOracle is IRateOracle {

    /// @notice Gets the address of the Lido stETH token
    /// @return Address of the Lido stETH token
    function stEth() external view returns (IStETH);

    /// @notice Gets the address of the Lido Oracle
    /// @return Address of the Lido Oracle
    function lidoOracle() external view returns (ILidoOracle);
}