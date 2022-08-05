// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Palette} from "./Palette.sol";
import {Traits} from "./Traits.sol";

enum MouthType {
    SMILE,
    GRATIFIED,
    POLITE,
    HMM,
    OOO,
    GRIN,
    SMOOCH,
    TOOTHY,
    SMIRK,
    VEE,
    CAT,
    BLEP
}

library Mouth {
    string constant fill = "black";

    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed) external pure returns (string memory) {
        MouthType mouthType = Traits.mouthType(_seed);

        if (mouthType == MouthType.SMILE) return _smile(fill);
        if (mouthType == MouthType.GRATIFIED) return _gratified(fill);
        if (mouthType == MouthType.POLITE) return _polite(fill);
        if (mouthType == MouthType.HMM) return _hmm(fill);
        if (mouthType == MouthType.OOO) return _ooo(fill);
        if (mouthType == MouthType.GRIN) return _grin(fill);
        if (mouthType == MouthType.SMOOCH) return _smooch(fill);
        if (mouthType == MouthType.TOOTHY) return _toothy(fill);
        if (mouthType == MouthType.CAT) return _cat(fill);
        if (mouthType == MouthType.VEE) return _vee(fill);
        if (mouthType == MouthType.BLEP) return _blep(fill);
        return _smirk(fill);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _smile(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M71 115.208C83.2665 139.324 116.641 138.602 129 115' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round'/>"
            );
    }

    function _gratified(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M80 115.139C88.4596 131.216 111.476 130.735 120 115' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round'/>"
            );
    }

    function _polite(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M90 110.081C94.2298 119.459 105.738 119.179 110 110' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round'/>"
            );
    }

    function _ooo(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M108 121.5C108 126.747 104.418 129 100 129C95.5817 129 92 126.747 92 121.5C92 116.253 95.5817 112 100 112C104.418 112 108 116.253 108 121.5Z' fill='",
                _fill,
                "'/>"
            );
    }

    function _smooch(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M97 100C118 95.9999 122 116 103.993 119C122 121 119 140.5 98 138' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round' stroke-linejoin='round'/>",
                "<path d='M131.055 124.545C131.141 124.54 131.238 124.505 131.348 124.44C131.462 124.378 131.569 124.309 131.67 124.233C132.713 123.467 133.612 122.675 134.366 121.856C135.123 121.033 135.699 120.199 136.091 119.354C136.484 118.505 136.655 117.664 136.606 116.829C136.574 116.276 136.454 115.776 136.248 115.33C136.042 114.884 135.773 114.505 135.442 114.192C135.11 113.879 134.733 113.647 134.309 113.495C133.885 113.34 133.437 113.277 132.966 113.304C132.381 113.339 131.88 113.517 131.465 113.838C131.049 114.156 130.727 114.563 130.498 115.057C130.208 114.597 129.839 114.231 129.388 113.96C128.942 113.689 128.425 113.571 127.836 113.606C127.364 113.633 126.927 113.749 126.524 113.953C126.125 114.152 125.777 114.427 125.48 114.777C125.184 115.127 124.959 115.535 124.807 116.002C124.658 116.469 124.6 116.979 124.633 117.532C124.682 118.367 124.951 119.183 125.44 119.98C125.928 120.773 126.597 121.534 127.446 122.262C128.295 122.987 129.28 123.669 130.401 124.308C130.514 124.371 130.629 124.427 130.745 124.475C130.866 124.527 130.969 124.55 131.055 124.545Z' fill='",
                _fill,
                "'/>"
            );
    }

    function _grin(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M79 119C90.8621 122.983 110.138 123.017 122 119' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round'/>"
            );
    }

    function _toothy(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M72 115L76.9006 121.006C78.7745 123.303 82.045 123.887 84.5981 122.381L86.358 121.343C88.6999 119.961 91.678 120.327 93.6157 122.235L96.2815 124.859C98.6159 127.157 102.362 127.158 104.697 124.861L107.373 122.231C109.311 120.326 112.287 119.961 114.628 121.342L116.393 122.383C118.945 123.888 122.214 123.306 124.088 121.012L129 115' stroke='",
                _fill,
                "' stroke-width='10' stroke-miterlimit='10' stroke-linecap='round'/>"
            );
    }

    function _cat(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M77 112.5C77 119.404 82.5964 125 89.5 125C93.9023 125 97.773 122.724 100 119.285C102.227 122.724 106.098 125 110.5 125C117.404 125 123 119.404 123 112.5' stroke='",
                _fill,
                "' stroke-width='10' stroke-linejoin='round' stroke-linecap='round'/>"
            );
    }

    function _vee(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M85 112L95.7711 117.027C98.4516 118.277 101.548 118.277 104.229 117.027L115 112' stroke='",
                _fill,
                "' stroke-width='10' stroke-linejoin='round' stroke-linecap='round'/>"
            );
    }

    function _hmm(string memory _fill) internal pure returns (string memory) {
        return string.concat("<path d='M83 119H118' stroke='", _fill, "' stroke-width='10' stroke-linecap='round'/>");
    }

    function _smirk(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M129 115C120.699 130.851 102.919 136.383 88.4211 131' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round'/>"
            );
    }

    function _blep(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M70 115C86.5517 120.557 113.448 120.606 130 115" stroke-width="10" stroke-linecap="round" stroke="',
                _fill,
                '"/>',
                '<path d="M96.2169 124.829C94.7132 149.357 132.515 145.477 126.034 121.514" stroke-width="8" stroke-linecap="round" stroke="',
                _fill,
                '"/>',
                '<path d="M111.011 121.05L113 141" stroke-width="4" stroke-linecap="round" stroke="',
                _fill,
                '"/>'
            );
    }
}