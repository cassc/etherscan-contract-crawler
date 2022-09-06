// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";
import {Traits} from "./Traits.sol";

enum CheekType {
    NONE,
    CIRCULAR,
    FRECKLES,
    BIG
}

library Cheeks {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed) external pure returns (string memory) {
        CheekType cheekType = Traits.cheekType(_seed);
        if (cheekType == CheekType.CIRCULAR) return _circular();
        if (cheekType == CheekType.FRECKLES) return _freckles();
        if (cheekType == CheekType.BIG) return _big();
        return "";
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _circular() internal pure returns (string memory) {
        return
            string.concat(
                "<g opacity='0.25'>",
                "<circle cx='148' cy='112' r='6' fill='black'/>",
                "<circle cx='52' cy='112' r='6' fill='black'/>",
                "</g>"
            );
    }

    function _big() internal pure returns (string memory) {
        return
            string.concat(
                "<g opacity='0.15'>",
                "<ellipse cx='150' cy='112' rx='11' ry='10' fill='black'/>",
                "<ellipse cx='50' cy='112' rx='11' ry='10' fill='black'/>",
                "</g>"
            );
    }

    function _freckles() internal pure returns (string memory) {
        return
            string.concat(
                "<g opacity='0.25'>",
                "<path d='M53 109.5C53 111.433 54.567 113 56.5 113C58.433 113 60 111.433 60 109.5C60 107.567 58.433 106 56.5 106C54.567 106 53 107.567 53 109.5Z' fill='black'/>",
                "<path d='M46 116.5C46 118.433 47.567 120 49.5 120C51.433 120 53 118.433 53 116.5C53 114.567 51.433 113 49.5 113C47.567 113 46 114.567 46 116.5Z' fill='black'/>",
                "<path d='M42 107.5C42 109.433 43.567 111 45.5 111C47.433 111 49 109.433 49 107.5C49 105.567 47.433 104 45.5 104C43.567 104 42 105.567 42 107.5Z' fill='black'/>",
                "<path d='M147 109.5C147 111.433 145.433 113 143.5 113C141.567 113 140 111.433 140 109.5C140 107.567 141.567 106 143.5 106C145.433 106 147 107.567 147 109.5Z' fill='black'/>",
                "<path d='M154 116.5C154 118.433 152.433 120 150.5 120C148.567 120 147 118.433 147 116.5C147 114.567 148.567 113 150.5 113C152.433 113 154 114.567 154 116.5Z' fill='black'/>",
                "<path d='M158 107.5C158 109.433 156.433 111 154.5 111C152.567 111 151 109.433 151 107.5C151 105.567 152.567 104 154.5 104C156.433 104 158 105.567 158 107.5Z' fill='black'/>",
                "</g>"
            );
    }
}