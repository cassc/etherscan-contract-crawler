// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IAloeBlend.sol";
import "./ISilo.sol";
import "./IVolatilityOracle.sol";

interface IFactory {
    /// @notice The address of the volatility oracle
    function volatilityOracle() external view returns (IVolatilityOracle);

    /// @notice Reports the vault's address (if one exists for the chosen parameters)
    function getVault(
        IUniswapV3Pool pool,
        ISilo silo0,
        ISilo silo1
    ) external view returns (IAloeBlend);

    /// @notice Reports whether the given vault was deployed by this factory
    function didCreateVault(IAloeBlend vault) external view returns (bool);

    /// @notice Creates a new Blend vault for the given pool + silo combination
    function createVault(
        IUniswapV3Pool pool,
        ISilo silo0,
        ISilo silo1
    ) external returns (IAloeBlend);
}