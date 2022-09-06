// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {SVG} from "./SVG.sol";
import {Eyes} from "./Eyes.sol";
import {Mouth} from "./Mouth.sol";
import {Cheeks} from "./Cheeks.sol";
import {Data} from "./Data.sol";

library Face {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed) internal pure returns (string memory) {
        uint256 faceSeed = uint256(keccak256(abi.encodePacked(_seed, "face")));
        bool reverse = (faceSeed /= 2) % 2 == 0;
        string memory rotation = ["1", "2", "4", "6", "-1", "-2", "-4", "-6"][faceSeed % 8];

        string memory circleAttributes = SVG.circleAttributes({
            _radius: "80",
            _coords: ["100", "100"],
            _fill: "white",
            _opacity: "0.2",
            _mixMode: "lighten",
            _attributes: SVG.filterAttribute("bibo-blur-lg")
        });

        string memory faceGroupAttributes = string.concat(
            "transform=",
            "'",
            "translate(100,100) scale(0.5) ",
            "rotate(",
            rotation,
            ")",
            "'"
        );

        return
            SVG.element(
                "g",
                faceGroupAttributes,
                SVG.element(
                    "rect",
                    SVG.rectAttributes({_width: "200", _height: "200", _fill: "#00000000", _attributes: ""})
                ),
                SVG.element("circle", circleAttributes),
                Eyes.render(_seed),
                Mouth.render(_seed),
                Cheeks.render(_seed),
                SVG.element(
                    "animateMotion",
                    SVG.animateMotionAttributes(reverse, "11s", "linear"),
                    Data.mpathJitterLg()
                )
            );
    }
}