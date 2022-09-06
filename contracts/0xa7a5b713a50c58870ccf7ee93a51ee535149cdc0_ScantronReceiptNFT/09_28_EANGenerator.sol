// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice EANGenerator
/// @dev This may have bugs but works for my purposes...
contract EANGenerator {
    uint256 private constant rightLookup = 540239147841653911603316;
    uint256 private constant leftLookup  = 61853319182102579328779;
    uint256 private constant gLookup     = 185115027151919713945879;

    uint256 private constant encodingLookup = 3154382249088410;

    function svgForBarcode(uint256 input) internal pure returns (string memory) {
        bytes
            memory barcode = '<svg width="37.290mm" height="27.550mm" viewBox="0 0 400 32" xmlns="http://www.w3.org/2000/svg">';
        for (uint256 i = 0; i < 114; i++) {
            if ((input >> i) & 1 == 1) {
                barcode = abi.encodePacked(
                    barcode,
                    '<rect x="',
                    Strings.toString(i + 9),
                    '" y="0" width="1" height="',
                    (i < 7 || (i >= 43 && i < 49) || (i > 90)) ? "100%" : "90%",
                    '" fill="black" />'
                );
            }
        }
        return string(abi.encodePacked(barcode, "</svg>"));
    }

    function generateCodesFor(uint256 input) internal pure returns (uint256) {
        unchecked {
            uint256 checksum;
            uint256 barcodePart = input;
            uint256 at;
            for (at = 0; at < 12; at++) {
                if (at % 2 == 0) {
                    checksum += (barcodePart % 10) * 3;
                } else {
                    checksum += (barcodePart % 10);
                }
                barcodePart /= 10;
            }
            checksum %= 10;
            if (checksum != 0) {
                checksum = 10 - checksum;
            }

            input *= 10;
            input += checksum;

            uint256 result = 24758800785707957341703372805;

            // left encoded digits
            uint256 flips = (encodingLookup >>
                (6 * (9 - (input / 10**12)))) & 63;

            // right
            for (at = 0; at < 6; at++) {
                result |=
                    ((rightLookup >> ((9 - (input % 10)) * 8)) & 0xff) <<
                    ((at) * 7 + 3);
                input /= 10;
            }

            // left
            for (at = 0; at < 6; at++) {
                uint256 lookup = ((flips >> at) & 1 == 0 ? leftLookup : gLookup);
                result |=
                    ((lookup >> ((9 - (input % 10)) * 8)) & 0xff) <<
                    (((at) * 7) + (3 + 5 + 7 * 6));
                input /= 10;
            }

                
            return result;
        }
    }
}