// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";

library TextBody {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32[] memory _text, uint256 yOffset, bool _small) internal pure returns (string memory) {
        string memory textLines = "";

        for (uint8 index = 0; index < _text.length; ++index) {
            textLines = string.concat(
                textLines,
                SVG.element(
                    "text",
                    SVG.textAttributes({
                        _fontSize: _small ? "14" : "26",
                        _fontFamily: "Norw, 'Courier New', monospace",
                        _coords: [
                            "60",
                            Util.uint256ToString(yOffset + index * (_small ? 20 : 30))
                        ],
                        _fill: "white",
                        _attributes: ""
                    }),
                    Util.bytes32ToString(_text[index])
                )
            );
        }

        return
            textLines;
    }
}