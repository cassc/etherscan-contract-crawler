//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../interfaces/balancer/IBalancerPool.sol';
import '../../interfaces/balancer/IBalancerV2Vault.sol';
import '../../interfaces/drops/IChainlinkPriceFactory.sol';
import '../../interfaces/drops/IDropsOracle.sol';
import '../../lib/BalancerLib.sol';

interface IWrappedstETH {
    function stETH() external view returns (address);

    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
}

/**
 * @title LP token price oracle for BalancerStablePool of wstETH-WETH
 */
contract WstETHWETHBalancerLPOracle is IDropsOracle {
    /// @notice address to stETH
    address public constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    /// @notice address to wstETH
    address public constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    /// @notice address to WETH
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice address to balancerVault
    address public constant vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /// @notice address to balancerVault
    bytes32 public constant poolId =
        0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080;

    /// @notice address to balancer Pool
    address public constant pool = 0x32296969Ef14EB0c6d29669C550D4a0449130230;

    /// @notice address to the price factory
    address public constant factory = 0xB08742E82cC6743D8a1Cf2473aD36c9Ea9D477fD;

    /* ========== VIEWS ========== */

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function latestAnswer() external view override returns (int256 answer) {
        uint256[] memory ethTotals = _getETHBalances();
        answer = int256(_getArithmeticMean(ethTotals));
    }

    /* ========== INTERNAL ========== */

    function _getETHBalances() internal view returns (uint256[] memory ethBalances) {
        uint256 WETH_Price = 1e18;

        uint256 stETHPrice = uint256(IChainlinkPriceFactory(factory).getETHPrice(stETH));
        uint256 wstETH_Price = (stETHPrice * IWrappedstETH(wstETH).getStETHByWstETH(1e18)) / 1e18;

        ethBalances = new uint256[](2);
        (, uint256[] memory balances, ) = IBalancerV2Vault(vault).getPoolTokens(poolId);
        ethBalances[0] = (wstETH_Price * balances[0]) / (10 ** 18);
        ethBalances[1] = (WETH_Price * balances[1]) / (10 ** 18);
    }

    function _getArithmeticMean(uint256[] memory ethTotals) internal view returns (uint256) {
        uint256 totalUsd = 0;
        for (uint256 i = 0; i < 2; i++) {
            totalUsd = totalUsd + ethTotals[i];
        }
        return BalancerLib.bdiv(totalUsd, IBalancerPool(pool).totalSupply());
    }
}