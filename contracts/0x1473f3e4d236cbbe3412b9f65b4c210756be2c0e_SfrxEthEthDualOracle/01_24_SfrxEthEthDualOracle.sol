// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= SfrxEthEthDualOracle =======================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Jon Walch: https://github.com/jonwalch

// Reviewers
// Drake Evans: https://github.com/DrakeEvans
// Dennis: https://github.com/denett

// ====================================================================
import { FrxEthEthDualOracle, ConstructorParams as FrxEthEthDualOracleParams } from "./FrxEthEthDualOracle.sol";
import { ISfrxEth } from "interfaces/ISfrxEth.sol";

struct ConstructorParams {
    FrxEthEthDualOracleParams frxEthEthDualOracleParams;
    address sfrxEthErc4626;
}

contract SfrxEthEthDualOracle is FrxEthEthDualOracle {
    /// @notice The address of the Erc20 token contract
    ISfrxEth public immutable SFRXETH_ERC4626;

    constructor(ConstructorParams memory params) FrxEthEthDualOracle(params.frxEthEthDualOracleParams) {
        SFRXETH_ERC4626 = ISfrxEth(params.sfrxEthErc4626);
    }

    // ====================================================================
    // View Helpers
    // ====================================================================

    function name() external view override returns (string memory _name) {
        _name = "sfrxEth Dual Oracle In Eth with Curve Pool EMA and Uniswap v3 TWAP and Frax and ETH Chainlink";
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    function _calculatePrices(
        uint256 ethPerFrxEthCurveEma,
        uint256 fraxPerFrxEthTwap,
        bool isBadDataEthUsdChainlink,
        uint256 usdPerEthChainlink,
        bool isBadDataFraxUsdChainlink,
        uint256 usdPerFraxChainlink
    ) internal view override returns (bool isBadData, uint256 priceLow, uint256 priceHigh) {
        (isBadData, priceLow, priceHigh) = super._calculatePrices({
            ethPerFrxEthCurveEma: ethPerFrxEthCurveEma,
            fraxPerFrxEthTwap: fraxPerFrxEthTwap,
            isBadDataEthUsdChainlink: isBadDataEthUsdChainlink,
            usdPerEthChainlink: usdPerEthChainlink,
            isBadDataFraxUsdChainlink: isBadDataFraxUsdChainlink,
            usdPerFraxChainlink: usdPerFraxChainlink
        });

        uint256 sfrxEthPricePerShare = SFRXETH_ERC4626.pricePerShare();

        priceLow = (sfrxEthPricePerShare * priceLow) / ORACLE_PRECISION;
        priceHigh = (sfrxEthPricePerShare * priceHigh) / ORACLE_PRECISION;
    }
}