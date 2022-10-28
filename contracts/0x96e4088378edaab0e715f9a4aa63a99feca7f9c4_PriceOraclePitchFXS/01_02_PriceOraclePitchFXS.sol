// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IFraxswap} from "@interfaces/IFraxFarm.sol";

/// @notice Provides the price of pitchFXS token in FRAX (wei)

contract PriceOraclePitchFXS {
    address public constant PITCHFXS_FRAXSWAP = address(0x0a92aC70B5A187fB509947916a8F63DD31600F80);
    address public constant PITCHFXS = address(0x11EBe21e9d7BF541A18e1E3aC94939018Ce88F0b);
    address public constant FRAX = address(0x853d955aCEf822Db058eb8505911ED77F175b99e);

    function getUSDPrice(address token) external view returns (uint256 priceInWei) {
        require(token == PITCHFXS, "!PITCHFXS");
        require(
            IFraxswap(PITCHFXS_FRAXSWAP).token0() == PITCHFXS && IFraxswap(PITCHFXS_FRAXSWAP).token1() == FRAX,
            "!TokenOrder"
        );

        // get the reserves from fraxswap
        (uint112 token0Reserve, uint112 token2Reserve, ) = IFraxswap(PITCHFXS_FRAXSWAP).getReserves();

        // convert to uint256 for return value
        uint256 token0Amt = uint256(token0Reserve);
        uint256 token1Amt = uint256(token2Reserve);

        // price is in FRAX wei
        priceInWei = (1e18 * token1Amt) / token0Amt;
    }
}