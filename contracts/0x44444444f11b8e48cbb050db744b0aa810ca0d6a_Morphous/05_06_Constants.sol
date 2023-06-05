// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @notice Constants used in Morphous.
library Constants {
    /// @notice ETH address.
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice sETH address.
    address internal constant _stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    /// @notice wstETH address.
    address internal constant _wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    /// @notice cETH address.
    address internal constant _cETHER = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    /// @notice WETH address.
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice DAI address.
    address internal constant _DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    /// @notice The address of Morpho Aave markets.
    address public constant _MORPHO_AAVE = 0x777777c9898D384F785Ee44Acfe945efDFf5f3E0;

    /// @notice The address of Morpho Aave markets.
    /// TODO: Replace this address with the correct one.
    address public constant _MORPHO_AAVE_V3 = 0x33333aea097c193e66081E930c33020272b33333;

    /// @notice Address of Aave Lending Pool contract.
    address internal constant _AAVE_LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    /// @notice Address of Balancer contract.
    address internal constant _BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /// @notice The address of Morpho Compound markets.
    address public constant _MORPHO_COMPOUND = 0x8888882f8f843896699869179fB6E4f7e3B58888;

    /// @notice Address of Factory Guard contract.
    address internal constant _FACTORY_GUARD_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    /////////////////////////////////////////////////////////////////
    /// --- ERRORS
    ////////////////////////////////////////////////////////////////

    /// @dev Error message when the caller is not allowed to call the function.
    error NOT_ALLOWED();

    /// @dev Error message when array length is invalid.
    error INVALID_LENGTH();

    /// @dev Error message when the caller is not allowed to call the function.
    error INVALID_LENDER();

    /// @dev Error message when the caller is not allowed to call the function.
    error INVALID_INITIATOR();

    /// @dev Error message when the market is invalid.
    error INVALID_MARKET();

    /// @dev Error message when the market is invalid.
    error INVALID_AGGREGATOR();

    /// @dev Error message when the deadline has passed.
    error DEADLINE_EXCEEDED();

    /// @dev Error message for when the amount of received tokens is less than the minimum amount.
    error NOT_ENOUGH_RECEIVED();
}