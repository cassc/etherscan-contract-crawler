// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";

library TextLine {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _text, uint256 yOffset, bool _small) internal pure returns (string memory) {
        return
            SVG.element(
                "text",
                SVG.textAttributes({
                    _fontSize: _small ? "14" : "26",
                    _fontFamily: "Norw, 'Courier New', monospace",
                    _coords: [
                        "60",
                        Util.uint256ToString(yOffset)
                    ],
                    _fill: "white",
                    _attributes: ""
                }),
                Util.bytes32ToString(_text)
            )
        ;
    }
}