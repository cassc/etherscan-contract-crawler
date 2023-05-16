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
// ================ FraxUsdcUniswapV3SingleTwapOracle =================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import { IStaticOracle } from "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";
import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import {
    IFraxUsdcUniswapV3SingleTwapOracle
} from "interfaces/oracles/abstracts/IFraxUsdcUniswapV3SingleTwapOracle.sol";

struct ConstructorParams {
    address fraxUsdcUniswapV3PairAddress;
    uint32 fraxUsdcTwapDuration;
    address fraxUsdcTwapBaseToken;
    address fraxUsdcTwapQuoteToken;
}

/// @title UniswapV3SingleTwapOracle
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An oracle for UniV3 Twap prices
abstract contract FraxUsdcUniswapV3SingleTwapOracle is ERC165Storage, IFraxUsdcUniswapV3SingleTwapOracle {
    /// @notice address of the Uniswap V3 pair
    address public immutable FRAX_USDC_UNI_V3_PAIR_ADDRESS;

    /// @notice The precision of the twap
    uint128 public constant FRAX_USDC_TWAP_PRECISION = 1e18;

    /// @notice The base token of the twap
    address public immutable FRAX_USDC_UNISWAP_V3_TWAP_BASE_TOKEN;

    /// @notice The quote token of the twap
    address public immutable FRAX_USDC_UNISWAP_V3_TWAP_QUOTE_TOKEN;

    /// @notice The duration of the twap
    uint32 public fraxUsdcTwapDuration;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(IFraxUsdcUniswapV3SingleTwapOracle).interfaceId });

        FRAX_USDC_UNI_V3_PAIR_ADDRESS = _params.fraxUsdcUniswapV3PairAddress;
        fraxUsdcTwapDuration = _params.fraxUsdcTwapDuration;
        FRAX_USDC_UNISWAP_V3_TWAP_BASE_TOKEN = _params.fraxUsdcTwapBaseToken;
        FRAX_USDC_UNISWAP_V3_TWAP_QUOTE_TOKEN = _params.fraxUsdcTwapQuoteToken;
    }

    /// @notice The ```_setFraxUsdcTwapDuration``` function sets duration of the twap
    /// @param _newTwapDuration The new twap duration
    function _setFraxUsdcTwapDuration(uint32 _newTwapDuration) internal {
        emit SetFraxUsdcTwapDuration({ oldTwapDuration: fraxUsdcTwapDuration, newTwapDuration: _newTwapDuration });
        fraxUsdcTwapDuration = _newTwapDuration;
    }

    function setFraxUsdcTwapDuration(uint32 _newTwapDuration) external virtual;

    /// @notice The ```_getFraxUsdcUniswapV3Twap``` function is called to get the twap
    /// @return _twap The twap price
    function _getFraxUsdcUniswapV3Twap() internal view returns (uint256 _twap) {
        address[] memory _pools = new address[](1);
        _pools[0] = FRAX_USDC_UNI_V3_PAIR_ADDRESS;

        _twap = IStaticOracle(0xB210CE856631EeEB767eFa666EC7C1C57738d438).quoteSpecificPoolsWithTimePeriod({
            baseAmount: FRAX_USDC_TWAP_PRECISION,
            baseToken: FRAX_USDC_UNISWAP_V3_TWAP_BASE_TOKEN,
            quoteToken: FRAX_USDC_UNISWAP_V3_TWAP_QUOTE_TOKEN,
            pools: _pools,
            period: fraxUsdcTwapDuration
        });
    }

    /// @notice The ```getFraxUsdcUniswapV3Twap``` function is called to get the twap
    /// @return _twap The twap price
    function getFraxUsdcUniswapV3Twap() external view virtual returns (uint256 _twap) {
        _twap = _getFraxUsdcUniswapV3Twap();
    }
}