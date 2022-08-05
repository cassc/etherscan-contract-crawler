// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Palette, DensityType, PolarityType} from "./Palette.sol";
import {Traits} from "./Traits.sol";
import {Data} from "./Data.sol";
import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";

library Body {
    uint256 constant circlesCount = 7;

    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        string[7] memory radii = ["64", "64", "64", "56", "48", "32", "24"];

        string memory backgroundFill = Palette.backgroundFill(_seed, _tokenId);
        string memory mixBlendMode = Traits.polarityType(_seed, _tokenId) == PolarityType.POSITIVE
            ? "lighten"
            : "multiply";

        string memory bodyGroupChildren = _bodyBackground(backgroundFill);

        for (uint8 index = 0; index < circlesCount; ++index) {
            bodyGroupChildren = string.concat(
                bodyGroupChildren,
                _bodyCircle(_seed, index, _tokenId, radii[index], mixBlendMode)
            );
        }
        return
            SVG.element(
                "g",
                string.concat(SVG.filterAttribute("bibo-blur"), 'shape-rendering="optimizeSpeed"'),
                bodyGroupChildren
            );
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _bodyCircle(
        bytes32 _seed,
        uint256 _index,
        uint256 _tokenId,
        string memory _radius,
        string memory _mixMode
    ) internal pure returns (string memory) {
        uint256 bodySeed = uint256(keccak256(abi.encodePacked(_seed, "body", _index)));
        string memory bodyFill1 = Palette.bodyFill(_seed, _index, _tokenId);
        string memory bodyFill2 = Palette.bodyFill(_seed, _index + circlesCount, _tokenId);
        string memory dur = Data.shortTimes(bodySeed /= Data.length);
        string[2] memory coords = (_index == 0) ? ["150", "150"] : Data.bodyPoints(bodySeed /= 2);
        bool reverse = bodySeed % 2 == 0;

        return
            SVG.element(
                "circle",
                SVG.circleAttributes({
                    _radius: _radius,
                    _coords: coords,
                    _fill: bodyFill1,
                    _opacity: "1",
                    _mixMode: _mixMode,
                    _attributes: ""
                }),
                SVG.element("animateMotion", SVG.animateMotionAttributes(reverse, dur, "linear"), Data.mpathJitterLg()),
                (_tokenId == 0) ? _genesis(bodyFill1, bodyFill2, dur) : ""
            );
    }

    function _genesis(
        string memory _bodyFill1,
        string memory _bodyFill2,
        string memory _dur
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<animate attributeName="fill" repeatCount="indefinite" values="',
                _bodyFill1,
                ";",
                _bodyFill2,
                ";",
                _bodyFill1,
                '" dur="',
                _dur,
                '"/>'
            );
    }

    function _bodyBackground(string memory _fill) internal pure returns (string memory) {
        return
            SVG.element("rect", SVG.rectAttributes({_width: "100%", _height: "100%", _fill: _fill, _attributes: ""}));
    }
}