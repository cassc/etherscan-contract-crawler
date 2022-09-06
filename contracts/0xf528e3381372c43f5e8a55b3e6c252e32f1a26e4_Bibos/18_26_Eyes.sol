// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Palette} from "libraries/Palette.sol";
import {Util} from "libraries/Util.sol";
import {SVG} from "libraries/SVG.sol";
import {Traits} from "libraries/Traits.sol";
import {Eyes2} from "libraries/Eyes2.sol";

enum EyeType {
    OVAL,
    SMILEY,
    WINK,
    ROUND,
    SLEEPY,
    CLOVER,
    DIZZY,
    STAR,
    HEART,
    HAHA,
    CYCLOPS,
    OPALINE
}

library Eyes {
    string constant fill = "black";

    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed) external pure returns (string memory) {
        EyeType eyeType = Traits.eyeType(_seed);

        if (eyeType == EyeType.OVAL) return _oval(fill);
        if (eyeType == EyeType.SMILEY) return _smiley(fill);
        if (eyeType == EyeType.WINK) return _wink(fill);
        if (eyeType == EyeType.ROUND) return _round(fill);
        if (eyeType == EyeType.SLEEPY) return _sleepy(fill);
        if (eyeType == EyeType.CLOVER) return _clover(fill);
        if (eyeType == EyeType.DIZZY) return _dizzy(fill);
        if (eyeType == EyeType.STAR) return _star(fill);
        if (eyeType == EyeType.HEART) return _heart(fill);
        if (eyeType == EyeType.HAHA) return _haha(fill);
        if (eyeType == EyeType.CYCLOPS) return _cyclops(fill);
        return Eyes2.opaline(fill);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _oval(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<ellipse cx="58" cy="79" rx="18" ry="20" fill="',
                _fill,
                '"/>',
                '<ellipse cx="142" cy="79" rx="18" ry="20" fill="',
                _fill,
                '"/>',
                '<ellipse cx="65" cy="75.5" rx="6" ry="6.5" fill="white"/>',
                '<ellipse cx="149" cy="75.5" rx="6" ry="6.5" fill="white"/>'
            );
    }

    function _clover(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M50 69L66 85M50 85L66 69" stroke="',
                _fill,
                '" stroke-width="24" stroke-linecap="round"/>',
                '<path d="M134 69L150 85M134 85L150 69" stroke="',
                _fill,
                '" stroke-width="24" stroke-linecap="round"/>',
                '<circle cx="149" cy="72" r="6" fill="white"/>',
                '<circle cx="65" cy="72" r="6" fill="white"/>'
            );
    }

    function _dizzy(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M59.6645 74.0529C61.0054 72.9366 59.3272 69.9131 56.2074 70.5958C53.2108 70.9583 50.279 75.8268 52.9588 80.7586C55.2103 85.6761 63.4411 88.7892 70.0358 84.4242C76.7252 80.5755 79.5444 69.1782 73.0767 60.6407C67.2313 51.9471 52.4557 48.7063 42.3791 56.7675C32.004 64.0877 29.2918 82.0505 39.5466 94.1708" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>',
                '<path d="M140.459 73.9503C139.143 75.046 140.79 78.0136 143.852 77.3435C146.793 76.9877 149.671 72.2092 147.04 67.3687C144.83 62.542 136.752 59.4865 130.279 63.7708C123.713 67.5484 120.946 78.7349 127.295 87.1145C133.032 95.6473 147.534 98.8282 157.424 90.9161C167.608 83.7313 170.27 66.1006 160.204 54.2045" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>'
            );
    }

    function _cyclops(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<ellipse cx="100" cy="70" rx="18" ry="20" fill="',
                _fill,
                '"/>',
                '<ellipse cx="107" cy="66.5" rx="6" ry="6.5" fill="white"/>'
            );
    }

    function _heart(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M58.0103 99C58.3112 99 58.66 98.8972 59.0567 98.6915C59.467 98.4995 59.8569 98.2801 60.2262 98.0332C64.0288 95.5649 67.3322 92.9731 70.1363 90.2579C72.9541 87.529 75.1358 84.7247 76.6815 81.8449C78.2272 78.9515 79 76.0374 79 73.1028C79 71.1556 78.6854 69.3797 78.0562 67.7753C77.427 66.1709 76.5652 64.7859 75.4709 63.6203C74.3767 62.4546 73.1045 61.5633 71.6546 60.9462C70.2047 60.3154 68.6522 60 66.9971 60C64.9453 60 63.1602 60.5211 61.6419 61.5633C60.1236 62.5918 58.913 63.9494 58.0103 65.6361C57.0938 63.9631 55.8764 62.6055 54.3581 61.5633C52.8534 60.5211 51.0684 60 49.0029 60C47.3478 60 45.7953 60.3154 44.3454 60.9462C42.9091 61.5633 41.637 62.4546 40.5291 63.6203C39.4211 64.7859 38.5525 66.1709 37.9233 67.7753C37.3078 69.3797 37 71.1556 37 73.1028C37 76.0374 37.7728 78.9515 39.3185 81.8449C40.8642 84.7247 43.0459 87.529 45.8637 90.2579C48.6815 92.9731 51.9849 95.5649 55.7738 98.0332C56.1568 98.2801 56.5467 98.4995 56.9433 98.6915C57.3537 98.8972 57.7093 99 58.0103 99Z" fill="',
                _fill,
                '"/>',
                '<path d="M142.01 99C142.311 99 142.66 98.8972 143.057 98.6915C143.467 98.4995 143.857 98.2801 144.226 98.0332C148.029 95.5649 151.332 92.9731 154.136 90.2579C156.954 87.529 159.136 84.7247 160.681 81.8449C162.227 78.9515 163 76.0374 163 73.1028C163 71.1556 162.685 69.3797 162.056 67.7753C161.427 66.1709 160.565 64.7859 159.471 63.6203C158.377 62.4546 157.105 61.5633 155.655 60.9462C154.205 60.3154 152.652 60 150.997 60C148.945 60 147.16 60.5211 145.642 61.5633C144.124 62.5918 142.913 63.9494 142.01 65.6361C141.094 63.9631 139.876 62.6055 138.358 61.5633C136.853 60.5211 135.068 60 133.003 60C131.348 60 129.795 60.3154 128.345 60.9462C126.909 61.5633 125.637 62.4546 124.529 63.6203C123.421 64.7859 122.553 66.1709 121.923 67.7753C121.308 69.3797 121 71.1556 121 73.1028C121 76.0374 121.773 78.9515 123.319 81.8449C124.864 84.7247 127.046 87.529 129.864 90.2579C132.681 92.9731 135.985 95.5649 139.774 98.0332C140.157 98.2801 140.547 98.4995 140.943 98.6915C141.354 98.8972 141.709 99 142.01 99Z" fill="',
                _fill,
                '"/>',
                '<circle cx="152" cy="74" r="6" fill="white"/>',
                '<circle cx="68" cy="74" r="6" fill="white"/>'
            );
    }

    function _smiley(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M40 77.5C46 71.8333 61.6 64.6 76 81" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>',
                '<path d="M160 77.5C154 71.8333 138.4 64.6 124 81" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>'
            );
    }

    function _sleepy(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M74.9877 69.8113C70.6588 76.8378 57.4625 87.8622 39.3086 75.748" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>',
                '<path d="M125.012 69.8113C129.341 76.8378 142.537 87.8622 160.691 75.748" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>'
            );
    }

    function _star(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M121.162 79.0869C121.502 80.5275 122.637 81.8486 124.907 84.4908L125.109 84.7264C124.84 87.7584 124.737 89.3509 125.27 90.6376C125.768 91.8434 126.645 92.8641 127.774 93.5533C128.979 94.2887 130.603 94.4663 133.706 94.7339L133.909 94.9695C136.179 97.6116 137.314 98.9327 138.707 99.5104C139.933 100.019 141.292 100.135 142.589 99.8422C144.064 99.5096 145.416 98.401 148.122 96.184L148.363 95.9863C151.467 96.2492 153.097 96.3497 154.415 95.8298C155.649 95.3426 156.694 94.4862 157.4 93.3833C158.153 92.2064 158.335 90.6206 158.609 87.589L158.85 87.3913C161.555 85.1743 162.907 84.0658 163.499 82.7048C164.019 81.5076 164.138 80.1803 163.838 78.9131C163.498 77.4725 162.363 76.1514 160.093 73.5092L159.891 73.2737C160.16 70.2417 160.263 68.6491 159.731 67.3624C159.232 66.1566 158.355 65.1359 157.226 64.4467C156.021 63.7113 154.397 63.5337 151.294 63.2661L151.091 63.0305C148.821 60.3884 147.686 59.0673 146.293 58.4896C145.067 57.9814 143.708 57.8653 142.411 58.1578C140.936 58.4904 139.584 59.599 136.878 61.816L136.637 62.0137C133.533 61.7508 131.903 61.6503 130.585 62.1702C129.351 62.6574 128.306 63.5138 127.6 64.6167C126.847 65.7936 126.666 67.3794 126.392 70.4109L126.15 70.6087C123.445 72.8257 122.093 73.9342 121.501 75.2952C120.981 76.4924 120.862 77.8197 121.162 79.0869Z" fill="',
                _fill,
                '"/>',
                '<path d="M36.4896 82.7048C37.0673 84.0658 38.3884 85.1743 41.0305 87.3913L41.2662 87.5891C41.5338 90.6206 41.7114 92.2064 42.4468 93.3833C43.1359 94.4862 44.1566 95.3426 45.3625 95.8298C46.6492 96.3497 48.2417 96.2492 51.2736 95.9863L51.5092 96.184C54.1514 98.401 55.4725 99.5096 56.9131 99.8422C58.1803 100.135 59.5076 100.019 60.7048 99.5104C62.0658 98.9327 63.1743 97.6116 65.3913 94.9695L65.589 94.7339C68.6206 94.4663 70.2064 94.2887 71.3833 93.5533C72.4862 92.8641 73.3427 91.8434 73.8299 90.6376C74.3498 89.3509 74.2492 87.7583 73.9864 84.7263L74.184 84.4908C76.401 81.8486 77.5096 80.5275 77.8422 79.0869C78.1347 77.8197 78.0186 76.4924 77.5104 75.2952C76.9327 73.9342 75.6116 72.8257 72.9695 70.6087L72.7339 70.411C72.4663 67.3794 72.2888 65.7936 71.5533 64.6167C70.8642 63.5138 69.8435 62.6574 68.6376 62.1702C67.3509 61.6503 65.7584 61.7508 62.7264 62.0137L62.4908 61.816C59.8486 59.599 58.5275 58.4904 57.0869 58.1578C55.8197 57.8653 54.4924 57.9814 53.2952 58.4896C51.9342 59.0673 50.8257 60.3884 48.6087 63.0305L48.411 63.2661C45.3795 63.5337 43.7937 63.7113 42.6168 64.4467C41.5139 65.1359 40.6574 66.1566 40.1702 67.3624C39.6504 68.6491 39.7509 70.2416 40.0137 73.2736L39.816 73.5092C37.599 76.1514 36.4904 77.4725 36.1578 78.9131C35.8653 80.1803 35.9814 81.5076 36.4896 82.7048Z" fill="',
                _fill,
                '"/>',
                '<circle cx="148" cy="73" r="6" fill="white"/>',
                '<circle cx="64" cy="73" r="6" fill="white"/>'
            );
    }

    function _wink(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M160 77.5C154 71.8333 138.4 64.6 124 81" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>',
                '<ellipse cx="58" cy="79" rx="18" ry="20" fill="',
                _fill,
                '"/>',
                '<ellipse cx="65" cy="75.5" rx="6" ry="6.5" fill="white"/>'
            );
    }

    function _haha(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M74 80.5L44 77.5833M74 80.5L57.8571 61M74 80.5L52.8571 94" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>',
                '<path d="M126 80.5L156 77.5833M126 80.5L142.143 61M126 80.5L147.143 94" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>'
            );
    }

    function _round(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<circle cx="142" cy="79" r="19" fill="',
                _fill,
                '"/>',
                '<circle cx="58" cy="79" r="19" fill="',
                _fill,
                '"/>',
                '<circle cx="65" cy="75" r="6" fill="white"/>',
                '<circle cx="149" cy="75" r="6" fill="white"/>'
            );
    }
}