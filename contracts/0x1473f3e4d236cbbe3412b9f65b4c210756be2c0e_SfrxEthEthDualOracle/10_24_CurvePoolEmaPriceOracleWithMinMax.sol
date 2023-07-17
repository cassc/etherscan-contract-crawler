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
// ================ CurvePoolEmaPriceOracleWithMinMax =================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import {
    ICurvePoolEmaPriceOracleWithMinMax
} from "interfaces/oracles/abstracts/ICurvePoolEmaPriceOracleWithMinMax.sol";
import { IEmaPriceOracleStableSwap } from "interfaces/IEmaPriceOracleStableSwap.sol";

struct ConstructorParams {
    address curvePoolEmaPriceOracleAddress;
    uint256 minimumCurvePoolEma;
    uint256 maximumCurvePoolEma;
}

/// @title CurvePoolEmaPriceOracleWithMinMax
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An oracle for getting EMA prices from Curve
abstract contract CurvePoolEmaPriceOracleWithMinMax is ERC165Storage, ICurvePoolEmaPriceOracleWithMinMax {
    /// @notice Curve pool, source of EMA
    address public immutable CURVE_POOL_EMA_PRICE_ORACLE;

    /// @notice Precision of Curve pool price_oracle()
    uint256 public constant CURVE_POOL_EMA_PRICE_ORACLE_PRECISION = 1e18;

    /// @notice Maximum price of token1 in token0 units of the EMA
    /// @dev Must match precision of EMA
    uint256 public minimumCurvePoolEma;

    /// @notice Maximum price of token1 in token0 units of the EMA
    /// @dev Must match precision of EMA
    uint256 public maximumCurvePoolEma;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(ICurvePoolEmaPriceOracleWithMinMax).interfaceId });

        CURVE_POOL_EMA_PRICE_ORACLE = _params.curvePoolEmaPriceOracleAddress;
        minimumCurvePoolEma = _params.minimumCurvePoolEma;
        maximumCurvePoolEma = _params.maximumCurvePoolEma;
    }

    /// @notice The ```setMaximumCurvePoolEma``` function sets the maximum price of the EMA
    /// @dev Must match precision of the EMA
    /// @param _maximumPrice The maximum price of the EMA
    function _setMaximumCurvePoolEma(uint256 _maximumPrice) internal {
        emit SetMaximumCurvePoolEma({ oldMaximum: maximumCurvePoolEma, newMaximum: _maximumPrice });
        maximumCurvePoolEma = _maximumPrice;
    }

    function setMaximumCurvePoolEma(uint256 _maximumPrice) external virtual;

    /// @notice The ```setEmaMinimum``` function sets the minimum price of the EMA
    /// @dev Must match precision of the EMA
    /// @param _minimumPrice The minimum price of the EMA
    function _setMinimumCurvePoolEma(uint256 _minimumPrice) internal {
        emit SetMinimumCurvePoolEma({ oldMinimum: minimumCurvePoolEma, newMinimum: _minimumPrice });
        minimumCurvePoolEma = _minimumPrice;
    }

    function setMinimumCurvePoolEma(uint256 _minimumPrice) external virtual;

    function _getCurvePoolToken1EmaPrice() internal view returns (uint256 _token1Price) {
        uint256 _priceRaw = IEmaPriceOracleStableSwap(CURVE_POOL_EMA_PRICE_ORACLE).price_oracle();
        uint256 _price = _priceRaw > maximumCurvePoolEma ? maximumCurvePoolEma : _priceRaw;

        _token1Price = _price < minimumCurvePoolEma ? minimumCurvePoolEma : _price;
    }

    /// @notice The ```getCurvePoolToken1EmaPrice``` function gets the price of the second token in the Curve pool (token1)
    /// @dev Returned in units of the first token (token0)
    /// @return _emaPrice The price of the second token in the Curve pool
    function getCurvePoolToken1EmaPrice() external view returns (uint256 _emaPrice) {
        return _getCurvePoolToken1EmaPrice();
    }
}