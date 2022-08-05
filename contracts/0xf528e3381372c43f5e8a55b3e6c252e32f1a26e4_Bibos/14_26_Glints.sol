// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Traits} from "libraries/Traits.sol";
import {Palette} from "./Palette.sol";
import {Data} from "./Data.sol";
import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";

library Glints {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed) external pure returns (string memory) {
        string memory glintsGroupChildren;
        uint256 glintCount = Traits.glintCount(_seed);

        uint256 glintSeed = uint256(keccak256(abi.encodePacked(_seed, "glint")));
        bool reverseRotate = glintSeed % 2 == 0;
        glintSeed /= 2;
        bool reverse = glintSeed % 2 == 0;
        glintSeed /= 2;
        string[2][3] memory coords = Data.glintPoints(glintSeed);
        glintSeed /= Data.length;

        for (uint8 index = 0; index < glintCount; index++) {
            glintsGroupChildren = string.concat(
                glintsGroupChildren,
                _glint(
                    Data.shortTimes(glintSeed),
                    Data.shorterTimes(glintSeed),
                    Data.longTimes(glintSeed),
                    coords[index],
                    reverseRotate,
                    reverse
                )
            );
        }

        return SVG.element("g", "id='glints'", glintsGroupChildren);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _glint(
        string memory _durationShort,
        string memory _durationShorter,
        string memory _durationLong,
        string[2] memory _coords,
        bool _reverseRotate,
        bool _reverse
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "g",
                _transformAttribute(_coords),
                SVG.element(
                    "g",
                    "",
                    SVG.element(
                        "circle",
                        SVG.circleAttributes({
                            _radius: "10",
                            _coords: ["0", "0"],
                            _fill: "white",
                            _opacity: "1.0",
                            _mixMode: "lighten",
                            _attributes: SVG.filterAttribute("bibo-blur-sm")
                        })
                    ),
                    SVG.element(
                        "path",
                        'fill-opacity="0.85" fill="white" style="mix-blend-mode:normal" fill-rule="evenodd" clip-rule="evenodd" d="M2.60676 11.4891C2.49095 12.4964 1.95054 13 0.985526 13C0.580218 13 0.223162 12.8644 -0.0856447 12.5932C-0.39445 12.322 -0.577804 11.9831 -0.635705 11.5763C-0.86731 9.71671 -1.10856 8.28329 -1.35947 7.27603C-1.59107 6.2494 -1.97708 5.47458 -2.51749 4.95157C-3.0386 4.42857 -3.85887 4.02179 -4.97829 3.73123C-6.07841 3.42131 -7.62244 3.05327 -9.61037 2.62712C-10.5368 2.43341 -11 1.89104 -11 0.999999C-11 0.593219 -10.8649 0.234868 -10.5947 -0.0750589C-10.3245 -0.384987 -9.98673 -0.569006 -9.58142 -0.627117C-7.61279 -0.878934 -6.07841 -1.13075 -4.97829 -1.38257C-3.87817 -1.63438 -3.0579 -2.03147 -2.51749 -2.57385C-1.97708 -3.11622 -1.59107 -3.92978 -1.35947 -5.01453C-1.10856 -6.09927 -0.86731 -7.60048 -0.635705 -9.51816C-0.500603 -10.5061 0.0398083 -11 0.985526 -11C1.95054 -11 2.49095 -10.4964 2.60676 -9.4891C2.83836 -7.64891 3.06997 -6.2155 3.30157 -5.18886C3.53317 -4.1816 3.91918 -3.42615 4.45959 -2.92252C5 -2.41889 5.82992 -2.0121 6.94934 -1.70218C8.06876 -1.41162 9.61279 -1.05327 11.5814 -0.627117C12.5271 -0.414042 13 0.128328 13 0.999999C13 1.92978 12.4692 2.47215 11.4077 2.62712C9.47768 2.91767 7.97226 3.19855 6.89144 3.46973C5.81062 3.74092 5 4.1477 4.45959 4.69007C3.91918 5.23244 3.53317 6.03632 3.30157 7.10169C3.06997 8.16707 2.83836 9.62954 2.60676 11.4891Z"',
                        string.concat(
                            '<animateTransform dur="1.5s" repeatCount="indefinite" calcMode="spline" keyTimes="0; 0.5; 1" keySplines="0.4 0 0.4 1; 0.4 0 0.4 1" values="1; 1.25; 1" attributeName="transform" attributeType="XML" type="scale" additive="sum" begin="',
                            _durationShorter,
                            '"/>'
                        )
                    ),
                    _animateTransform(_durationShort, _reverseRotate)
                ),
                SVG.element(
                    "animateMotion",
                    SVG.animateMotionAttributes(_reverse, _durationLong, "linear"),
                    Data.mpathJitterLg()
                )
            );
    }

    function _transformAttribute(string[2] memory _coords) internal pure returns (string memory) {
        return string.concat('transform="translate(', _coords[0], ",", _coords[1], ') scale(1)"');
    }

    function _animateTransform(string memory _dur, bool _reverseRotate) internal pure returns (string memory) {
        string memory reverseRotate = _reverseRotate ? "from='0 0 0' to='360 0 0'" : "from='360 0 0' to='0 0 0'";

        return
            SVG.element(
                "animateTransform",
                string.concat(
                    'attributeName="transform" ',
                    "dur=",
                    Util.quote(_dur),
                    'repeatCount="indefinite" ',
                    'type="rotate" ',
                    reverseRotate
                )
            );
    }
}