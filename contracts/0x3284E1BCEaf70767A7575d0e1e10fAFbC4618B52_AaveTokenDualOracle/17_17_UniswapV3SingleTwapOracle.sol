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
// ==================== UniswapV3SingleTwapOracle =====================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "../../../interfaces/oracles/abstracts/IUniswapV3SingleTwapOracle.sol";

struct ConstructorParams {
    address uniswapV3PairAddress;
    uint32 twapDuration;
    address baseToken;
    address quoteToken;
}

/// @title UniswapV3SingleTwapOracle
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An oracle for UniV3 Twap prices
abstract contract UniswapV3SingleTwapOracle is ERC165Storage, IUniswapV3SingleTwapOracle {
    /// @notice address of the Uniswap V3 pair
    address public immutable UNI_V3_PAIR_ADDRESS;

    /// @notice The precision of the twap
    uint128 public constant TWAP_PRECISION = 1e18;

    /// @notice The base token of the twap
    address public immutable UNISWAP_V3_TWAP_BASE_TOKEN;

    /// @notice The quote token of the twap
    address public immutable UNISWAP_V3_TWAP_QUOTE_TOKEN;

    /// @notice The duration of the twap
    uint32 public twapDuration;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(IUniswapV3SingleTwapOracle).interfaceId });

        UNI_V3_PAIR_ADDRESS = _params.uniswapV3PairAddress;
        twapDuration = _params.twapDuration;
        UNISWAP_V3_TWAP_BASE_TOKEN = _params.baseToken;
        UNISWAP_V3_TWAP_QUOTE_TOKEN = _params.quoteToken;
    }

    /// @notice The ```_setTwapDuration``` function sets duration of the twap
    /// @param _newTwapDuration The new twap duration
    function _setTwapDuration(uint32 _newTwapDuration) internal {
        emit SetTwapDuration({ oldTwapDuration: twapDuration, newTwapDuration: _newTwapDuration });
        twapDuration = _newTwapDuration;
    }

    function setTwapDuration(uint32 _newTwapDuration) external virtual;

    /// @notice The ```_getUniswapV3Twap``` function is called to get the twap
    /// @return _twap The twap price
    function _getUniswapV3Twap() internal view returns (uint256 _twap) {
        address[] memory _pools = new address[](1);
        _pools[0] = UNI_V3_PAIR_ADDRESS;
        _twap = IStaticOracle(0xB210CE856631EeEB767eFa666EC7C1C57738d438).quoteSpecificPoolsWithTimePeriod({
            baseAmount: TWAP_PRECISION,
            baseToken: UNISWAP_V3_TWAP_BASE_TOKEN,
            quoteToken: UNISWAP_V3_TWAP_QUOTE_TOKEN,
            pools: _pools,
            period: twapDuration
        });
    }

    /// @notice The ```getUniswapV3Twap``` function is called to get the twap
    /// @return _twap The twap price
    function getUniswapV3Twap() external view virtual returns (uint256 _twap) {
        return _getUniswapV3Twap();
    }
}