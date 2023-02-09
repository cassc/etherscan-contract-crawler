// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {Trigonometry} from "trig/Trigonometry.sol";

import {IPaletteGenerator} from "@/contracts/interfaces/IPaletteGenerator.sol";

/// @notice A palette generator that generates a palette from a GnuPlot
/// colormap.
/// @author fiveoutofnine
contract GnuPlotPaletteGenerator is IPaletteGenerator {
    using FixedPointMathLib for uint256;

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    /// @dev Reverts if the position is not a valid input.
    /// @param _position Position in the colormap.
    modifier isValidPosition(uint256 _position) {
        if (_position > 1e18) {
            revert InvalidPosition(_position);
        }

        _;
    }

    // -------------------------------------------------------------------------
    // Generators
    // -------------------------------------------------------------------------

    /// @inheritdoc IPaletteGenerator
    function r(uint256 _position)
        external
        pure
        isValidPosition(_position)
        returns (uint256)
    {
        unchecked {
            // We multiply by 1e9 to maintain the scale.
            return _position.sqrt() * 1e9;
        }
    }

    /// @inheritdoc IPaletteGenerator
    function g(uint256 _position)
        external
        pure
        isValidPosition(_position)
        returns (uint256)
    {
        return _position.rpow(3, 1e18);
    }

    /// @inheritdoc IPaletteGenerator
    function b(uint256 _position)
        external
        pure
        isValidPosition(_position)
        returns (uint256)
    {
        unchecked {
            // The multiplication won't overflow because the `isValidPosition`
            // modifier checks that `_position` is less than 1e18. Also, we
            // divide by 1e18 to maintain the scale.
            int256 value = Trigonometry.sin(
                (_position * Trigonometry.TWO_PI) / 1e18
            );

            return value < 0 ? 0 : uint256(value);
        }
    }
}