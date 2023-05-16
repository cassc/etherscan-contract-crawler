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
// ============== CurvePoolVirtualPriceOracleWithMinMax ===============
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import {
    ICurvePoolVirtualPriceOracleWithMinMax
} from "interfaces/oracles/abstracts/ICurvePoolVirtualPriceOracleWithMinMax.sol";
import { IVirtualPriceStableSwap } from "interfaces/IVirtualPriceStableSwap.sol";

struct ConstructorParams {
    address curvePoolVirtualPriceAddress;
    uint256 minimumCurvePoolVirtualPrice;
    uint256 maximumCurvePoolVirtualPrice;
}

/// @title CurvePoolVirtualPriceOracleWithMinMax
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An oracle for getting curve LP virtual price
abstract contract CurvePoolVirtualPriceOracleWithMinMax is ERC165Storage, ICurvePoolVirtualPriceOracleWithMinMax {
    /// @notice Curve pool, source of virtual price
    address public immutable CURVE_POOL_VIRTUAL_PRICE_ADDRESS;

    /// @notice Precision of Curve pool get_virtual_price()
    uint256 public constant CURVE_POOL_VIRTUAL_PRICE_PRECISION = 1e18;

    /// @notice Minimum virtual price of Curve pool allowed
    uint256 public minimumCurvePoolVirtualPrice;

    /// @notice Maximum virtual price of Curve pool allowed
    uint256 public maximumCurvePoolVirtualPrice;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(ICurvePoolVirtualPriceOracleWithMinMax).interfaceId });

        // Curve pool config
        CURVE_POOL_VIRTUAL_PRICE_ADDRESS = _params.curvePoolVirtualPriceAddress;
        minimumCurvePoolVirtualPrice = _params.minimumCurvePoolVirtualPrice;
        maximumCurvePoolVirtualPrice = _params.maximumCurvePoolVirtualPrice;
    }

    /// @notice The ```_setMinimumCurvePoolVirtualPrice``` function is called to set the minimum virtual price
    /// @dev Contains no access control
    /// @param _newMinimum The new minimum price
    function _setMinimumCurvePoolVirtualPrice(uint256 _newMinimum) internal {
        emit SetMinimumCurvePoolVirtualPrice({ oldMinimum: minimumCurvePoolVirtualPrice, newMinimum: _newMinimum });
        minimumCurvePoolVirtualPrice = _newMinimum;
    }

    function setMinimumCurvePoolVirtualPrice(uint256 _newMinimum) external virtual;

    /// @notice The ```_setMaximumCurvePoolVirtualPrice``` function is called to set the maximum virtual price
    /// @dev Contains no access control
    /// @param _newMaximum The new maximum price
    function _setMaximumCurvePoolVirtualPrice(uint256 _newMaximum) internal {
        emit SetMaximumCurvePoolVirtualPrice({ oldMaximum: maximumCurvePoolVirtualPrice, newMaximum: _newMaximum });
        maximumCurvePoolVirtualPrice = _newMaximum;
    }

    function setMaximumCurvePoolVirtualPrice(uint256 _newMaximum) external virtual;

    /// @notice The ```_getCurvePoolVirtualPrice``` function is called to get the virtual price
    /// @return _virtualPrice The virtual price
    function _getCurvePoolVirtualPrice() internal view returns (uint256 _virtualPrice) {
        _virtualPrice = IVirtualPriceStableSwap(CURVE_POOL_VIRTUAL_PRICE_ADDRESS).get_virtual_price();

        // Cap the price at current max
        _virtualPrice = _virtualPrice > maximumCurvePoolVirtualPrice ? maximumCurvePoolVirtualPrice : _virtualPrice;

        // Price should never be below 1
        _virtualPrice = _virtualPrice < minimumCurvePoolVirtualPrice ? minimumCurvePoolVirtualPrice : _virtualPrice;
    }

    /// @notice The ```getCurvePoolVirtualPrice``` function is called to get the virtual price
    /// @return _virtualPrice The virtual price
    function getCurvePoolVirtualPrice() external view virtual returns (uint256 _virtualPrice) {
        return _getCurvePoolVirtualPrice();
    }
}