// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

interface IPriceOracleUpgradeable {
    function zoneToken() external view returns(address);

    function lpZoneEth() external view returns(IUniswapV2Pair);

    function getOutAmount(address token, uint256 tokenAmount) external view returns (uint256);

    function mintPriceInZone(uint256 _mintPrice) external view returns (uint256);

    function getLPFairPrice() external view returns (uint256);
}