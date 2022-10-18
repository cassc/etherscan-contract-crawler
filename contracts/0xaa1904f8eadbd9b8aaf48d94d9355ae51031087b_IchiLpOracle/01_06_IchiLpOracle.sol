// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import './UsingBaseOracle.sol';
import '../interfaces/IBaseOracle.sol';
import '../interfaces/ichi/IICHIVault.sol';

contract IchiLpOracle is UsingBaseOracle, IBaseOracle {
    constructor(IBaseOracle _base) UsingBaseOracle(_base) {}

    /**
     * @notice Return lp token price in USD, with 18 decimals of precision.
     * @param token The underlying token address for which to get the price.
     * @return Price in USD
     */
    function getPrice(address token) external view override returns (uint256) {
        IICHIVault vault = IICHIVault(token);
        address token0 = vault.token0();
        address token1 = vault.token1();

        (uint256 r0, uint256 r1) = vault.getTotalAmounts();
        uint256 px0 = base.getPrice(address(token0));
        uint256 px1 = base.getPrice(address(token1));
        uint256 t0Decimal = IERC20Metadata(token0).decimals();
        uint256 t1Decimal = IERC20Metadata(token1).decimals();

        uint256 totalReserve = (r0 * px0) /
            10**t0Decimal +
            (r1 * px1) /
            10**t1Decimal;

        return (totalReserve * 1e18) / vault.totalSupply();
    }
}