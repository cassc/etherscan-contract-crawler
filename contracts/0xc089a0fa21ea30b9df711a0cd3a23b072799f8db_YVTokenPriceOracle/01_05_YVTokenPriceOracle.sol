//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../interfaces/yearn/IYearnVault.sol';
import '../../interfaces/drops/IDropsOracle.sol';
import '../../interfaces/drops/IChainlinkPriceFactory.sol';

/**
 * @title yearn finance vault tokne price oracle
 */
contract YVTokenPriceOracle is IDropsOracle {
    /// @notice address to the yearn vault
    IYearnVault public immutable vault;

    /// @notice address to the price factory
    IChainlinkPriceFactory public immutable factory;

    constructor(IChainlinkPriceFactory _factory, IYearnVault _vault) {
        require(address(_factory) != address(0), '_factory address cannot be 0');
        require(address(_vault) != address(0), '_vault address cannot be 0');

        factory = _factory;
        vault = _vault;
    }

    /* ========== VIEWS ========== */

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function latestAnswer() external view override returns (int256 answer) {
        uint256 nativeTokenPrice = uint256(factory.getETHPrice(vault.token()));
        require(nativeTokenPrice > 0, '!token price');

        answer = int256((nativeTokenPrice * vault.pricePerShare()) / (10 ** vault.decimals()));
    }
}