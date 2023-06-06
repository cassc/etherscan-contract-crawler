// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SVG.sol";
import {Utils} from "../../utils/Utils.sol";
import {LibPRNG} from "../../utils/LibPRNG.sol";

/// @title ConstellationLib
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library ConstellationLib {
    // Constellations
    using LibPRNG for LibPRNG.PRNG;

    struct GenerateConstellationParams {
        uint256 x;
        uint256 y;
        uint16 rotationInDegrees;
        uint16 rotationCenterX;
        uint16 rotationCenterY;
        string starColor;
        bool fluxConstellation;
        bytes32 moonSeed;
    }

    function getLittleDipper(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory handle = string.concat(
            getStar(params, x, y),
            getStar(params, x + 11, y + 9),
            getStar(params, x + 26, y + 15),
            getStar(params, x + 43, y + 14)
        );
        string memory cup = string.concat(
            getStar(params, x + 57, y + 5),
            getStar(params, x + 64, y + 14),
            getStar(params, x + 47, y + 23)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                string.concat(cup, handle)
            );
    }

    function getBigDipper(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory cup = string.concat(
            getStar(params, x, y + 16),
            getStar(params, x + 11, y),
            getStar(params, x + 38, y + 13),
            getStar(params, x + 33, y + 30)
        );
        string memory handle = string.concat(
            getStar(params, x + 46, y + 45),
            getStar(params, x + 54, y + 58),
            getStar(params, x + 78, y + 66)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                string.concat(cup, handle)
            );
    }

    function getAries(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory stars = string.concat(
            getStar(params, x, y),
            getStar(params, x + 35, y - 19),
            getStar(params, x + 50, y - 21),
            getStar(params, x + 55, y - 16)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getPisces(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory upperLine = string.concat(
            getStar(params, x, y),
            getStar(params, x + 7, y - 8),
            getStar(params, x + 17, y - 20),
            getStar(params, x + 24, y - 32),
            getStar(params, x + 21, y - 41),
            getStar(params, x + 30, y - 47)
        );
        string memory lowerLine = string.concat(
            getStar(params, x + 9, y - 2),
            getStar(params, x + 28, y - 7),
            getStar(params, x + 36, y - 5),
            getStar(params, x + 52, y - 6)
        );
        string memory lowerCirclePart1 = string.concat(
            getStar(params, x + 60, y - 2),
            getStar(params, x + 65, y - 6),
            getStar(params, x + 70, y - 2),
            getStar(params, x + 71, y + 5)
        );
        string memory lowerCirclePart2 = string.concat(
            getStar(params, x + 66, y + 9),
            getStar(params, x + 58, y + 8),
            getStar(params, x + 57, y + 1)
        );

        string memory stars = string.concat(
            upperLine,
            lowerLine,
            lowerCirclePart1,
            lowerCirclePart2
        );
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getAquarius(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory bottomDownLine = string.concat(
            getStar(params, x, y),
            getStar(params, x + 12, y - 3),
            getStar(params, x + 20, y + 5),
            getStar(params, x + 22, y + 21)
        );
        string memory topAcrossLine = string.concat(
            getStar(params, x + 8, y - 21),
            getStar(params, x + 14, y - 26),
            getStar(params, x + 18, y - 21),
            getStar(params, x + 26, y - 27),
            getStar(params, x + 68, y - 10)
        );
        string memory middleDownLine = string.concat(
            getStar(params, x + 29, y - 11),
            getStar(params, x + 39, y - 1)
        );

        string memory stars = string.concat(
            bottomDownLine,
            topAcrossLine,
            middleDownLine
        );
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getCapricornus(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory top = string.concat(
            getStar(params, x, y),
            getStar(params, x + 8, y - 1),
            getStar(params, x + 30, y + 5)
        );
        string memory left = string.concat(
            getStar(params, x + 7, y + 7),
            getStar(params, x + 13, y + 16),
            getStar(params, x + 30, y + 29)
        );
        string memory right = string.concat(
            getStar(params, x + 34, y + 26),
            getStar(params, x + 59, y + 3),
            getStar(params, x + 65, y - 3)
        );
        string memory stars = string.concat(top, left, right);
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getSagittarius(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        string memory stars = string.concat(
            getSagittariusLeft(params),
            getSagittariusMiddle(params),
            getSagittariusRight(params)
        );
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getOphiuchus(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory stars = string.concat(
            getStar(params, x, y),
            getStar(params, x + 3, y - 22),
            getStar(params, x + 11, y - 32),
            getStar(params, x + 19, y - 24),
            getStar(params, x + 22, y + 5),
            getStar(params, x + 9, y + 4)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                // Avoid stack too deep error by adding last star here
                string.concat(stars, getStar(params, x + 33, y + 12))
            );
    }

    function getScorpius(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory top = string.concat(
            getStar(params, x, y),
            getStar(params, x + 3, y - 10),
            getStar(params, x + 9, y - 15),
            getStar(params, x + 14, y - 1)
        );
        string memory middle = string.concat(
            getStar(params, x + 19, y + 2),
            getStar(params, x + 21, y + 6),
            getStar(params, x + 25, y + 16),
            getStar(params, x + 25, y + 32)
        );
        string memory bottom1 = string.concat(
            getStar(params, x + 32, y + 37),
            getStar(params, x + 42, y + 39),
            getStar(params, x + 50, y + 33)
        );
        string memory bottom2 = string.concat(
            getStar(params, x + 47, y + 30),
            getStar(params, x + 44, y + 23)
        );
        string memory stars = string.concat(top, middle, bottom1, bottom2);
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getLibra(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory triangle = string.concat(
            getStar(params, x, y),
            getStar(params, x + 6, y - 17),
            getStar(params, x + 23, y - 19)
        );
        string memory left = string.concat(
            getStar(params, x + 9, y + 13),
            getStar(params, x + 7, y + 18)
        );
        string memory right = string.concat(
            getStar(params, x + 21, y - 6),
            getStar(params, x + 32, y + 5)
        );
        string memory stars = string.concat(triangle, left, right);
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getVirgo(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory middle = string.concat(
            getStar(params, x + 8, y),
            getStar(params, x + 11, y - 11),
            getStar(params, x + 10, y - 26),
            getStar(params, x + 22, y - 28),
            getStar(params, x + 28, y - 10)
        );
        string memory top = string.concat(
            getStar(params, x + 4, y - 32),
            getStar(params, x, y - 46),
            getStar(params, x + 34, y - 34)
        );
        string memory bottomLeft = string.concat(
            getStar(params, x + 21, y + 12),
            getStar(params, x + 24, y + 10),
            getStar(params, x + 30, y + 18)
        );
        string memory bottomRight = string.concat(
            getStar(params, x + 33, y - 7),
            getStar(params, x + 37, y - 4),
            getStar(params, x + 48, y + 9)
        );
        string memory stars = string.concat(
            middle,
            top,
            bottomLeft,
            bottomRight
        );
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getLeo(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory loop = string.concat(
            getStar(params, x, y),
            getStar(params, x + 4, y - 10),
            getStar(params, x + 14, y - 12),
            getStar(params, x + 35, y + 3),
            getStar(params, x + 45, y + 21),
            getStar(params, x + 30, y + 12)
        );
        string memory top = string.concat(
            getStar(params, x + 17, y - 19),
            getStar(params, x + 11, y - 30),
            getStar(params, x + 2, y - 29)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                string.concat(loop, top)
            );
    }

    function getCancer(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory stars = string.concat(
            getStar(params, x, y),
            getStar(params, x + 14, y - 21),
            getStar(params, x + 28, y - 12),
            getStar(params, x + 12, y - 29),
            getStar(params, x + 11, y - 49)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getGemini(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        string memory stars = string.concat(
            getGeminiLeftPerson(params),
            getGeminiRightPerson(params)
        );
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getTaurus(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory left = string.concat(
            getStar(params, x, y),
            getStar(params, x + 5, y - 13),
            getStar(params, x + 18, y - 2)
        );
        string memory middle1 = string.concat(
            getStar(params, x + 18, y + 11),
            getStar(params, x + 22, y + 5),
            getStar(params, x + 22, y + 9)
        );
        string memory middle2 = string.concat(
            getStar(params, x + 23, y + 13),
            getStar(params, x + 26, y + 9),
            getStar(params, x + 27, y + 13)
        );
        string memory bottom = string.concat(
            getStar(params, x + 34, y + 19),
            getStar(params, x + 49, y + 24),
            getStar(params, x + 51, y + 29)
        );
        string memory stars = string.concat(left, middle1, middle2, bottom);
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    // Helpers

    function getTransform(
        uint16 rotationInDegrees,
        uint16 rotationCenterX,
        uint16 rotationCenterY
    ) internal pure returns (string memory) {
        return
            svg.prop(
                "transform",
                string.concat(
                    "rotate(",
                    Utils.uint2str(rotationInDegrees),
                    " ",
                    Utils.uint2str(rotationCenterX),
                    " ",
                    Utils.uint2str(rotationCenterY),
                    ")"
                )
            );
    }

    function getStarTransform(uint256 x, uint256 y)
        internal
        pure
        returns (string memory)
    {
        return
            svg.prop(
                "transform",
                string.concat(
                    "translate(",
                    Utils.uint2str(x),
                    ",",
                    Utils.uint2str(y),
                    ") scale(0.03)"
                )
            );
    }

    function getStar(
        GenerateConstellationParams memory params,
        uint256 x,
        uint256 y
    ) internal pure returns (string memory) {
        string memory opacity;
        if (params.fluxConstellation) {
            LibPRNG.PRNG memory prng;
            prng.seed(
                keccak256(
                    abi.encodePacked(
                        params.rotationInDegrees,
                        params.moonSeed,
                        x,
                        y
                    )
                )
            );
            // Minimum 30, max 100
            opacity = Utils.uint2str(prng.uniform(71) + 30);
        } else {
            opacity = "100";
        }

        return
            svg.path(
                string.concat(
                    svg.prop(
                        "d",
                        "M 40 60 L 63.511 72.361 L 59.021 46.180 L 78.042 27.639 L 51.756 23.820 L 40 0 L 28.244 23.820 L 1.958 27.639 L 20.979 46.180 L 16.489 72.361 L 40 60"
                    ),
                    svg.prop("fill", params.starColor),
                    svg.prop("filter", "url(#glo)"),
                    svg.prop("opacity", string.concat(opacity, "%")),
                    getStarTransform(x, y)
                )
            );
    }

    function makeConstellation(
        uint16 rotationInDegrees,
        uint16 rotationCenterX,
        uint16 rotationCenterY,
        string memory starElt
    ) internal pure returns (string memory) {
        return
            svg.g(
                getTransform(
                    rotationInDegrees,
                    rotationCenterX,
                    rotationCenterY
                ),
                string.concat(
                    // Glow filter
                    svg.filter(
                        svg.prop("id", "glo"),
                        string.concat(
                            svg.feGaussianBlur(
                                string.concat(
                                    svg.prop("stdDeviation", "4"),
                                    svg.prop("result", "blur")
                                )
                            ),
                            svg.feMerge(
                                string.concat(
                                    svg.feMergeNode(svg.prop("in", "blur")),
                                    svg.feMergeNode(svg.prop("in", "blur")),
                                    svg.feMergeNode(svg.prop("in", "blur")),
                                    svg.feMergeNode(
                                        svg.prop("in", "SourceGraphic")
                                    )
                                )
                            )
                        )
                    ),
                    starElt
                )
            );
    }

    // Individual constellation helpers

    // Sagittarius helpers for groups of stars as we get stack too deep errors
    // including all stars in one function

    function getSagittariusLeft(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;
        return
            string.concat(
                getStar(params, x, y),
                getStar(params, x + 11, y + 5),
                getStar(params, x + 18, y + 2),
                getStar(params, x + 22, y + 7),
                getStar(params, x + 19, y + 13),
                getStar(params, x + 19, y - 7),
                getStar(params, x + 11, y - 17)
            );
    }

    function getSagittariusMiddle(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;
        return
            string.concat(
                getStar(params, x + 27, y - 6),
                getStar(params, x + 30, y - 10),
                getStar(params, x + 31, y - 20),
                getStar(params, x + 26, y - 21),
                getStar(params, x + 36, y - 20),
                getStar(params, x + 42, y - 28)
            );
    }

    function getSagittariusRight(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;
        return
            string.concat(
                getStar(params, x + 33, y - 3),
                getStar(params, x + 36, y - 9),
                getStar(params, x + 45, y - 15),
                getStar(params, x + 55, y - 11),
                getStar(params, x + 60, y - 7),
                getStar(params, x + 55, y + 6),
                getStar(params, x + 53, y + 14),
                getStar(params, x + 44, y + 12),
                getStar(params, x + 43, y + 23)
            );
    }

    // Gemini helpers for groups of stars as we get stack too deep errors
    // including all stars in one function

    function getGeminiLeftPerson(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;
        string memory leftPersonTop = string.concat(
            getStar(params, x, y),
            getStar(params, x + 10, y - 12),
            getStar(params, x + 13, y - 6),
            getStar(params, x + 20, y - 7)
        );
        string memory leftPersonBottom1 = string.concat(
            getStar(params, x + 13, y + 4),
            getStar(params, x + 13, y + 15),
            getStar(params, x + 11, y + 23)
        );
        string memory leftPersonBottom2 = string.concat(
            getStar(params, x + 13, y + 34),
            getStar(params, x + 1, y + 21),
            getStar(params, x + 3, y + 38)
        );
        return
            string.concat(leftPersonTop, leftPersonBottom1, leftPersonBottom2);
    }

    function getGeminiRightPerson(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;
        string memory rightPersonTop = string.concat(
            getStar(params, x + 28, y - 16),
            getStar(params, x + 29, y - 6),
            getStar(params, x + 38, y - 7)
        );
        string memory rightPersonBottom1 = string.concat(
            getStar(params, x + 28, y + 9),
            getStar(params, x + 30, y + 18),
            getStar(params, x + 30, y + 30)
        );
        string memory rightPersonBottom2 = string.concat(
            getStar(params, x + 25, y + 35),
            getStar(params, x + 40, y + 32)
        );
        return
            string.concat(
                rightPersonTop,
                rightPersonBottom1,
                rightPersonBottom2
            );
    }
}