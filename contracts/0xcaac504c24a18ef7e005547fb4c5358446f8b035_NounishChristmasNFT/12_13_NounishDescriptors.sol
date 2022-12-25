// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {NoggleSVGs} from "./NoggleSVGs.sol";
import {OneThroughSixCharacterSVGs} from "./OneThroughSixCharacterSVGs.sol";

library NounishDescriptors {
    function characterName(uint8 character) internal pure returns (string memory) {
        if (character == 1) {
            return "Cardinal";
        } else if (character == 2) {
            return "Swan";
        } else if (character == 3) {
            return "Blockhead";
        } else if (character == 4) {
            return "Dad";
        } else if (character == 5) {
            return "Trout Sniffer";
        } else if (character == 6) {
            return "Elf";
        } else if (character == 7) {
            return "Mothertrucker";
        } else if (character == 8) {
            return "Girl";
        } else if (character == 9) {
            return "Lamp";
        } else if (character == 10) {
            return "Mean One";
        } else if (character == 11) {
            return "Miner";
        } else if (character == 12) {
            return "Mrs. Claus";
        } else if (character == 13) {
            return "Noggleman";
        } else if (character == 14) {
            return "Noggle Tree";
        } else if (character == 15) {
            return "Nutcracker";
        } else if (character == 16) {
            return "Partridge in a Pear Tree";
        } else if (character == 17) {
            return "Rat King";
        } else if (character == 18) {
            return "Reindeer S";
        } else if (character == 19) {
            return "Reindeer Pro Max";
        } else if (character == 20) {
            return "Santa S";
        } else if (character == 21) {
            return "Santa Max Pro";
        } else if (character == 22) {
            return "Skeleton";
        } else if (character == 23) {
            return "Chunky Snowman";
        } else if (character == 24) {
            return "Slender Snowman";
        } else if (character == 25) {
            return "Snowman Pro Max";
        } else if (character == 26) {
            return "Sugar Plum Fairy";
        } else if (character == 27) {
            return "Short Thief";
        } else if (character == 28) {
            return "Tall Thief";
        } else if (character == 29) {
            return "Train";
        } else if (character == 30) {
            return "Christmas Tree";
        } else if (character == 31) {
            return "Yeti S";
        } else if (character == 32) {
            return "Yeti Pro Max";
        }
        return "";
    }

    /// @dev wanted to make the most of contract space, only renders through character 6
    function characterSVG(uint8 character) internal pure returns (string memory) {
        if (character == 1) {
            return OneThroughSixCharacterSVGs.cardinal();
        } else if (character == 2) {
            return OneThroughSixCharacterSVGs.swan();
        } else if (character == 3) {
            return OneThroughSixCharacterSVGs.blockhead();
        } else if (character == 4) {
            return OneThroughSixCharacterSVGs.dad();
        } else if (character == 5) {
            return OneThroughSixCharacterSVGs.troutSniffer();
        } else if (character == 6) {
            return OneThroughSixCharacterSVGs.elf();
        }
        return "";
    }

    function noggleTypeName(uint8 noggleType) internal pure returns (string memory) {
        if (noggleType == 1) {
            return "Noggles S";
        } else if (noggleType == 2) {
            return "Cool Noggles";
        } else if (noggleType == 3) {
            return "Noggles Pro Max";
        }
        return "";
    }

    function noggleTypeSVG(uint8 noggleType) internal pure returns (string memory) {
        if (noggleType == 1) {
            return NoggleSVGs.basic();
        } else if (noggleType == 2) {
            return NoggleSVGs.cool();
        } else if (noggleType == 3) {
            return NoggleSVGs.large();
        }
        return "";
    }

    function noggleColorName(uint8 noggleColor) internal pure returns (string memory) {
        if (noggleColor == 1) {
            return "Dark Plum";
        } else if (noggleColor == 2) {
            return "Warm Red";
        } else if (noggleColor == 3) {
            return "Peppermint";
        } else if (noggleColor == 4) {
            return "Cold Blue";
        } else if (noggleColor == 5) {
            return "Ring-a-Ding";
        }
        return "";
    }

    function noggleColorHex(uint8 noggleColor) internal pure returns (string memory) {
        if (noggleColor == 1) {
            return "513340";
        } else if (noggleColor == 2) {
            return "bd2d24";
        } else if (noggleColor == 3) {
            return "4ab49a";
        } else if (noggleColor == 4) {
            return "0827f5";
        } else if (noggleColor == 5) {
            return "f0c14d";
        }
        return "";
    }

    function backgroundColorName(uint8 background) internal pure returns (string memory) {
        if (background == 1) {
            return "Douglas Fir";
        } else if (background == 2) {
            return "Night";
        } else if (background == 3) {
            return "Rooftop";
        } else if (background == 4) {
            return "Mistletoe";
        } else if (background == 5) {
            return "Spice";
        }
        return "";
    }

    function backgroundColorHex(uint8 background) internal pure returns (string memory) {
        if (background == 1) {
            return "3e5d25";
        } else if (background == 2) {
            return "100d98";
        } else if (background == 3) {
            return "403037";
        } else if (background == 4) {
            return "326849";
        } else if (background == 5) {
            return "651d19";
        }
        return "";
    }

    function tintColorName(uint8 tint) internal pure returns (string memory) {
        if (tint == 1) {
            return "Boot Black";
        } else if (tint == 2) {
            return "Fairydust";
        } else if (tint == 3) {
            return "Elf";
        } else if (tint == 4) {
            return "Plum";
        } else if (tint == 5) {
            return "Explorer";
        } else if (tint == 6) {
            return "Hot Cocoa";
        } else if (tint == 7) {
            return "Carrot";
        } else if (tint == 8) {
            return "Spruce";
        } else if (tint == 9) {
            return "Holly";
        } else if (tint == 10) {
            return "Sleigh";
        } else if (tint == 11) {
            return "Jolly";
        } else if (tint == 12) {
            return "Coal";
        } else if (tint == 13) {
            return "Snow White";
        }
        return "";
    }

    function tintColorHex(uint8 tint) internal pure returns (string memory) {
        if (tint == 1) {
            return "000000";
        } else if (tint == 2) {
            return "2a46ff";
        } else if (tint == 3) {
            return "f38b7c";
        } else if (tint == 4) {
            return "7c3c58";
        } else if (tint == 5) {
            return "16786c";
        } else if (tint == 6) {
            return "36262d";
        } else if (tint == 7) {
            return "cb7300";
        } else if (tint == 8) {
            return "06534a";
        } else if (tint == 9) {
            return "369f49";
        } else if (tint == 10) {
            return "ff0e0e";
        } else if (tint == 11) {
            return "fd5442";
        } else if (tint == 12) {
            return "453f41";
        } else if (tint == 13) {
            return "ffffff";
        }
        return "";
    }
}