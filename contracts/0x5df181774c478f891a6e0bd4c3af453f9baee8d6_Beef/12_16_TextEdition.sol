// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";

library TextEdition {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _text) internal pure returns (string memory) {
        return
            SVG.element(
                "text",
                SVG.textAttributes({
                    _fontSize: "26",
                    _fontFamily: "Norw, 'Courier New', monospace",
                    _coords: ["12", "35"],
                    _fill: "white",
                    _attributes: ""
                }),
                Util.bytes32ToString(_text)
            );
    }
}