// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Palette} from "./Palette.sol";
import {Data} from "./Data.sol";
import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";
import {Traits} from "./Traits.sol";

enum MoteType {
    NONE,
    FLOATING,
    RISING,
    FALLING,
    GLISTENING
}

library Motes {
    uint256 constant GLINT_COUNT = 20;

    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed, uint256 _tokenId) external pure returns (string memory) {
        string memory motesChildren;

        MoteType moteType = Traits.moteType(_seed);
        if (moteType == MoteType.NONE) return "";

        for (uint8 i = 0; i < GLINT_COUNT; i++) {
            uint256 moteSeed = uint256(keccak256(abi.encodePacked(_seed, "mote", i)));

            string memory dur = Data.longTimes(moteSeed /= Data.length);
            string memory delay = Data.shorterTimes(moteSeed /= Data.length);
            string[2] memory coords = Data.motePoints(moteSeed /= Data.length);
            string memory radius = (moteSeed /= 2) % 2 == 0 ? "1" : "2";
            string memory opacity = Palette.opacity(moteSeed /= Palette.opacityLength, _seed, _tokenId);
            bool reverse = moteSeed % 2 == 0;

            if (moteType == MoteType.FLOATING)
                motesChildren = string.concat(motesChildren, _floatingMote(radius, coords, opacity, dur, reverse));
            else if (moteType == MoteType.RISING)
                motesChildren = string.concat(motesChildren, _risingMote(radius, coords, opacity, dur));
            else if (moteType == MoteType.FALLING)
                motesChildren = string.concat(motesChildren, _fallingMote(radius, coords, opacity, dur));
            else if (moteType == MoteType.GLISTENING)
                motesChildren = string.concat(
                    motesChildren,
                    _glisteningMote(radius, coords, opacity, dur, reverse, delay)
                );
        }

        return SVG.element({_type: "g", _attributes: "", _children: motesChildren});
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _risingMote(
        string memory _radius,
        string[2] memory _coords,
        string memory _opacity,
        string memory _dur
    ) internal pure returns (string memory) {
        return
            SVG.element({
                _type: "g",
                _attributes: 'transform="translate(0,25)"',
                _children: SVG.element(
                    "circle",
                    SVG.circleAttributes(_radius, _coords, "white", _opacity, "lighten", ""),
                    _animateTransform(_dur, "-100"),
                    _animate(_dur)
                )
            });
    }

    function _floatingMote(
        string memory _radius,
        string[2] memory _coords,
        string memory _opacity,
        string memory _dur,
        bool _reverse
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "circle",
                SVG.circleAttributes(_radius, _coords, "white", _opacity, "lighten", ""),
                SVG.element(
                    "animateMotion",
                    SVG.animateMotionAttributes(_reverse, _dur, "linear"),
                    Data.mpathJitterSm()
                )
            );
    }

    function _fallingMote(
        string memory _radius,
        string[2] memory _coords,
        string memory _opacity,
        string memory _dur
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "g",
                'transform="translate(0,-25)">',
                SVG.element(
                    "circle",
                    SVG.circleAttributes(_radius, _coords, "white", _opacity, "lighten", ""),
                    _animateTransform(_dur, "100"),
                    _animate(_dur)
                )
            );
    }

    function _glisteningMote(
        string memory _radius,
        string[2] memory _coords,
        string memory _opacity,
        string memory _dur,
        bool _reverse,
        string memory _delay
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "g",
                'opacity="0"',
                SVG.element(
                    "animate",
                    string.concat(
                        'calcMode="spline" keyTimes="0; 0.5; 1" keySplines="0.4 0 0.4 1; 0.4 0 0.4 1" attributeName="opacity" values="0;1;0" dur="1.5s" repeatCount="indefinite" begin="',
                        _delay,
                        '"/>'
                    )
                ),
                SVG.element(
                    "circle",
                    SVG.circleAttributes(_radius, _coords, "white", _opacity, "lighten", ""),
                    SVG.element(
                        "animateMotion",
                        SVG.animateMotionAttributes(_reverse, _dur, "paced"),
                        Data.mpathJitterSm()
                    )
                )
            );
    }

    function _animateTransform(string memory _dur, string memory _to) internal pure returns (string memory) {
        string memory attributes = string.concat(
            'attributeName="transform" ',
            "dur=",
            Util.quote(_dur),
            'repeatCount="indefinite" ',
            'type="translate" ',
            'additive="sum" ',
            'from="0 0" ',
            'to="0 ',
            _to,
            '"'
        );

        return SVG.element("animateTransform", attributes);
    }

    function _animate(string memory _dur) internal pure returns (string memory) {
        return
            SVG.element(
                "animate",
                string.concat(
                    'attributeName="opacity" ',
                    'values="0;1;0" ',
                    "dur=",
                    Util.quote(_dur),
                    'repeatCount="indefinite" '
                )
            );
    }
}