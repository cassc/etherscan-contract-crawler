// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SVG.sol";

/// @title MoonSvg
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library MoonSvg {
    struct SvgContainerParams {
        uint16 x;
        uint16 y;
        uint16 width;
        uint16 height;
    }

    struct EllipseParams {
        uint16 cx;
        uint16 cy;
        uint256 rx;
        uint16 ry;
        string color;
        bool forceUseBackgroundColor;
    }

    struct RectParams {
        uint16 width;
        uint16 height;
        string color;
        string gradientColor;
    }

    struct BorderParams {
        uint16 radius;
        uint16 width;
        string borderType;
        string color;
    }

    function getBackgroundRadialGradientDefinition(
        RectParams memory rectParams,
        uint256 moonVerticalRadius
    ) internal pure returns (string memory) {
        return
            svg.radialGradient(
                string.concat(
                    svg.prop("id", "brG"),
                    // Set radius to 75% to smooth out the radial gradient against
                    // the background and moon color
                    svg.prop("r", "75%")
                ),
                string.concat(
                    svg.stop(
                        string.concat(
                            svg.prop(
                                "offset",
                                string.concat(
                                    Utils.uint2str(
                                        // Ensure that the gradient has the rect color up to at least the moon radius
                                        // Note: the reason we do moon radius * 100 * 3 / 2 is because
                                        // we multiply by 100 to get a percent, then multiply by 3 and divide by 2
                                        // to get ~1.5 * moon radius, which is sufficiently large given the background radial
                                        // gradient radius is being scaled by 75% (50% would be normal size, 75% is scaled up),
                                        // which smooths out the gradient and reduces the presence of a color band
                                        (((moonVerticalRadius * 100) * 3) / 2) /
                                            rectParams.height
                                    ),
                                    "%"
                                )
                            ),
                            svg.prop("stop-color", rectParams.color)
                        )
                    ),
                    svg.stop(
                        string.concat(
                            svg.prop("offset", "100%"),
                            svg.prop("stop-color", rectParams.gradientColor)
                        )
                    )
                )
            );
    }

    function getMoonFilterDefinition(uint16 moonRadiusY)
        internal
        pure
        returns (string memory)
    {
        uint16 position = moonRadiusY * 2;
        return
            svg.filter(
                string.concat(svg.prop("id", "mF")),
                string.concat(
                    svg.feSpecularLighting(
                        string.concat(
                            svg.prop("result", "out"),
                            svg.prop("specularExponent", "20"),
                            svg.prop("lighting-color", "#bbbbbb")
                        ),
                        svg.fePointLight(
                            string.concat(
                                svg.prop("x", position),
                                svg.prop("y", position),
                                svg.prop("z", position)
                            )
                        )
                    ),
                    svg.feComposite(
                        string.concat(
                            svg.prop("in", "SourceGraphic"),
                            svg.prop("in2", "out"),
                            svg.prop("operator", "arithmetic"),
                            svg.prop("k1", "0"),
                            svg.prop("k2", "1"),
                            svg.prop("k3", "1"),
                            svg.prop("k4", "0")
                        )
                    )
                )
            );
    }

    function getMoonFilterMask(
        SvgContainerParams memory svg1,
        SvgContainerParams memory svg2,
        EllipseParams memory ellipse1,
        EllipseParams memory ellipse2,
        RectParams memory rect
    ) internal pure returns (string memory) {
        return
            svg.mask(
                svg.prop("id", "mfM"),
                string.concat(
                    svg.rect(
                        string.concat(
                            svg.prop("width", rect.width),
                            svg.prop("height", rect.height),
                            svg.prop("fill", "#000")
                        )
                    ),
                    getEllipseElt(
                        svg1,
                        ellipse1,
                        // Black rect for masking purposes; where this rect is visible will be hidden
                        "#000",
                        // White ellipse for masking purposes; where this ellipse is visible will be shown
                        "#FFF"
                    ),
                    getEllipseElt(
                        svg2,
                        ellipse2,
                        // Black rect for masking purposes; where this rect is visible will be hidden
                        "#000",
                        // White ellipse for masking purposes; where this ellipse is visible will be shown
                        "#FFF"
                    )
                )
            );
    }

    function getEllipseElt(
        SvgContainerParams memory svgContainer,
        EllipseParams memory ellipse,
        string memory rectBackgroundColor,
        string memory ellipseColor
    ) internal pure returns (string memory) {
        return
            svg.svgTag(
                string.concat(
                    svg.prop("x", svgContainer.x),
                    svg.prop("y", svgContainer.y),
                    svg.prop("height", svgContainer.height),
                    svg.prop("width", svgContainer.width)
                ),
                svg.ellipse(
                    string.concat(
                        svg.prop("cx", ellipse.cx),
                        svg.prop("cy", ellipse.cy),
                        svg.prop("rx", ellipse.rx),
                        svg.prop("ry", ellipse.ry),
                        svg.prop(
                            "fill",
                            ellipse.forceUseBackgroundColor
                                ? rectBackgroundColor
                                : ellipseColor
                        )
                    )
                )
            );
    }

    function getBorderStyleProp(BorderParams memory border)
        internal
        pure
        returns (string memory)
    {
        return
            svg.prop(
                "style",
                string.concat(
                    "outline:",
                    Utils.uint2str(border.width),
                    "px ",
                    border.borderType,
                    " ",
                    border.color,
                    ";outline-offset:-",
                    Utils.uint2str(border.width),
                    "px;border-radius:",
                    Utils.uint2str(border.radius),
                    "%"
                )
            );
    }

    function getMoonBackgroundMaskDefinition(
        RectParams memory rect,
        uint256 moonRadius
    ) internal pure returns (string memory) {
        return
            svg.mask(
                svg.prop("id", "mbM"),
                string.concat(
                    svg.rect(
                        string.concat(
                            svg.prop("width", rect.width),
                            svg.prop("height", rect.height),
                            // Everything under a white pixel will be visible
                            svg.prop("fill", "#FFF")
                        )
                    ),
                    svg.circle(
                        string.concat(
                            svg.prop("cx", rect.width / 2),
                            svg.prop("cy", rect.height / 2),
                            // Add 1 to moon radius as slight buffer.
                            svg.prop("r", moonRadius + 1)
                        )
                    )
                )
            );
    }

    function getDefinitions(
        RectParams memory rect,
        SvgContainerParams memory svg1,
        SvgContainerParams memory svg2,
        EllipseParams memory ellipse1,
        EllipseParams memory ellipse2,
        string memory alienArtMoonFilterDefinition
    ) internal pure returns (string memory) {
        return
            svg.defs(
                string.concat(
                    getBackgroundRadialGradientDefinition(rect, ellipse1.ry),
                    bytes(alienArtMoonFilterDefinition).length > 0
                        ? alienArtMoonFilterDefinition
                        : getMoonFilterDefinition(ellipse1.ry),
                    getMoonBackgroundMaskDefinition(rect, ellipse1.ry),
                    getMoonFilterMask(svg1, svg2, ellipse1, ellipse2, rect)
                )
            );
    }

    function getMoonSvgProps(uint16 borderRadius)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                svg.prop("xmlns", "http://www.w3.org/2000/svg"),
                // Include id so that the moon element can be accessed by JS
                svg.prop("id", "moon"),
                svg.prop("height", "100%"),
                svg.prop("viewBox", "0 0 200 200"),
                svg.prop(
                    "style",
                    string.concat(
                        "border-radius:",
                        Utils.uint2str(borderRadius),
                        "%;max-height:100vh"
                    )
                )
            );
    }

    function generateMoon(
        RectParams memory rect,
        SvgContainerParams memory svg1,
        SvgContainerParams memory svg2,
        EllipseParams memory ellipse1,
        EllipseParams memory ellipse2,
        BorderParams memory border,
        string memory alienArt,
        string memory alienArtMoonFilterDefinition
    ) internal pure returns (string memory) {
        string memory ellipse1elt = getEllipseElt(
            svg1,
            ellipse1,
            rect.color,
            ellipse1.color
        );
        string memory ellipse2elt = getEllipseElt(
            svg2,
            ellipse2,
            rect.color,
            ellipse2.color
        );

        string memory rectProps = string.concat(
            svg.prop(
                "fill",
                bytes(rect.gradientColor).length > 0 ? "url(#brG)" : rect.color
            ),
            svg.prop("width", rect.width),
            svg.prop("height", rect.height),
            svg.prop("rx", string.concat(Utils.uint2str(border.radius), "%")),
            svg.prop("ry", string.concat(Utils.uint2str(border.radius), "%"))
        );

        string memory definitions = getDefinitions(
            rect,
            svg1,
            svg2,
            ellipse1,
            ellipse2,
            alienArtMoonFilterDefinition
        );

        return
            svg.svgTag(
                getMoonSvgProps(border.radius),
                string.concat(
                    definitions,
                    svg.svgTag(
                        svg.NULL,
                        string.concat(
                            svg.rect(
                                string.concat(
                                    rectProps,
                                    getBorderStyleProp(border)
                                )
                            ),
                            // Intentionally put alien art behind the moon in svg ordering
                            svg.g(
                                // Apply mask to block out the moon area from alien art,
                                // which is necessary in order for the moon to be clearly visible when displayed
                                svg.prop("mask", "url(#mbM)"),
                                alienArt
                            ),
                            svg.g(
                                string.concat(
                                    // Apply filter to moon
                                    svg.prop("filter", "url(#mF)"),
                                    // Apply mask to ensure filter only applies to the visible portion of the moon
                                    svg.prop("mask", "url(#mfM)")
                                ),
                                string.concat(ellipse1elt, ellipse2elt)
                            )
                        )
                    )
                )
            );
    }
}