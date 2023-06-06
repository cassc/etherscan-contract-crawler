// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {MoonCalculations} from "./MoonCalculations.sol";
import {MoonSvg} from "./MoonSvg.sol";
import {MoonConfig} from "./MoonConfig.sol";
import {MoonImageConfig} from "./MoonStructs.sol";

/// @title MoonRenderer
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library MoonRenderer {
    function getLunarCycleDistanceFromDateAsRotationInDegrees(uint256 date)
        internal
        pure
        returns (uint16)
    {
        return
            uint16(
                // Round to nearest multiple of 10000, which ensures that progressScaled will be properly rounded rather than having truncation occur during integer division
                MoonCalculations.roundToNearestMultiple(
                    MoonCalculations.calculateLunarCycleDistanceFromDate(date) *
                        360,
                    10000
                ) / 10000
            );
    }

    function _render(
        bytes32 moonSeed,
        MoonCalculations.MoonPhase phase,
        // Represent a fraction as progressOutOf10000 out of 10000
        // e.g. 0.5 -> progressOutOf10000 = 5000, 0.1234 -> 1234
        uint256 progressOutOf10000,
        string memory alienArt,
        string memory alienArtMoonFilter
    ) internal pure returns (string memory) {
        MoonImageConfig memory moonConfig = MoonConfig.getMoonConfig(moonSeed);

        MoonSvg.SvgContainerParams memory svg1 = MoonSvg.SvgContainerParams({
            x: 0,
            y: 0,
            width: moonConfig.moonRadius,
            height: moonConfig.viewHeight
        });
        MoonSvg.SvgContainerParams memory svg2 = MoonSvg.SvgContainerParams({
            x: 0,
            y: 0,
            width: moonConfig.moonRadius,
            height: moonConfig.viewHeight
        });

        MoonSvg.EllipseParams memory ellipse1 = MoonSvg.EllipseParams({
            cx: moonConfig.moonRadius,
            cy: moonConfig.moonRadius,
            rx: moonConfig.moonRadius,
            ry: moonConfig.moonRadius,
            color: moonConfig.colors.moon,
            forceUseBackgroundColor: false
        });

        MoonSvg.EllipseParams memory ellipse2 = MoonSvg.EllipseParams({
            cx: 0,
            cy: moonConfig.moonRadius,
            rx: moonConfig.moonRadius,
            ry: moonConfig.moonRadius,
            color: moonConfig.colors.moon,
            forceUseBackgroundColor: false
        });

        // Round to nearest multiple of 10000, which ensures that progressScaled will be properly rounded rather than having truncation occur during integer division.
        uint256 progressScaled = MoonCalculations.roundToNearestMultiple(
            progressOutOf10000 * moonConfig.moonRadius,
            10000
        ) / 10000;

        if (phase == MoonCalculations.MoonPhase.WANING_GIBBOUS) {
            svg1.x = 0;
            // Subtract 1 from svg2.x, add 1 to svg2.width, add 1 to ellipse2.cx to ensure smooth border between ellipses
            svg2.x = moonConfig.moonRadius - 1;
            svg2.width += 1;

            ellipse1.cx = moonConfig.moonRadius;
            ellipse1.rx = moonConfig.moonRadius;
            ellipse2.cx = 1;
            ellipse2.rx = moonConfig.moonRadius - progressScaled;
        } else if (phase == MoonCalculations.MoonPhase.WANING_CRESCENT) {
            svg1.x = 0;
            svg2.x = 0;

            // Add 1 to svg2.width to ensure smooth border between ellipses
            svg2.width += 1;

            ellipse1.cx = moonConfig.moonRadius;
            ellipse1.rx = moonConfig.moonRadius;
            ellipse2.cx = moonConfig.moonRadius;
            ellipse2.rx = progressScaled;
            ellipse2.forceUseBackgroundColor = true;
        } else if (phase == MoonCalculations.MoonPhase.WAXING_CRESCENT) {
            svg1.x = moonConfig.moonRadius;
            // Subtract 1 from svg2.x, add 1 to ellipse2.cx, add 1 to ellipse2.rx to ensure smooth border between ellipses
            svg2.x = moonConfig.moonRadius - 1;
            svg2.width += 1;

            ellipse1.cx = 0;
            ellipse1.rx = moonConfig.moonRadius;
            ellipse2.cx = 1;
            ellipse2.rx = moonConfig.moonRadius - progressScaled + 1;
            ellipse2.forceUseBackgroundColor = true;
        } else if (phase == MoonCalculations.MoonPhase.WAXING_GIBBOUS) {
            svg1.x = 0;
            svg2.x = moonConfig.moonRadius;

            // Add 1 to svg1.width to ensure smooth border between ellipses
            svg1.width += 1;

            ellipse1.cx = moonConfig.moonRadius;
            ellipse1.rx = progressScaled;
            ellipse2.cx = 0;
            ellipse2.rx = moonConfig.moonRadius;
        }

        // Add svg offsets
        svg1.x += moonConfig.xOffset;
        svg2.x += moonConfig.xOffset;
        svg1.y += moonConfig.yOffset;
        svg2.y += moonConfig.yOffset;

        return
            MoonSvg.generateMoon(
                MoonSvg.RectParams({
                    color: moonConfig.colors.background,
                    gradientColor: moonConfig.colors.backgroundGradientColor,
                    width: moonConfig.viewWidth,
                    height: moonConfig.viewHeight
                }),
                svg1,
                svg2,
                ellipse1,
                ellipse2,
                MoonSvg.BorderParams({
                    radius: moonConfig.borderRadius,
                    width: moonConfig.borderWidth,
                    borderType: moonConfig.borderType,
                    color: moonConfig.colors.border
                }),
                alienArt,
                alienArtMoonFilter
            );
    }

    function renderWithTimestamp(
        bytes32 moonSeed,
        // UTC timestamp.
        uint256 timestamp,
        string memory alienArt,
        string memory alienArtFilter
    ) internal pure returns (string memory) {
        (
            MoonCalculations.MoonPhase phase,
            uint256 progressOutOf10000
        ) = MoonCalculations.timestampToPhase(timestamp);
        return
            _render(
                moonSeed,
                phase,
                progressOutOf10000,
                alienArt,
                alienArtFilter
            );
    }
}