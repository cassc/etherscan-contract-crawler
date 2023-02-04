// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

/*
    @dev        Library to convert epoch timestamp to a human-readable Date-Time string
    @dependency uses BokkyPooBahsDateTimeLibrary.sol library internally
 */
library DateTime {
    using Strings for uint256;

    bytes public constant MONTHS = bytes("JanFebMarAprMayJunJulAugSepOctNovDec");

    /**
     *   @dev returns month as short (3-letter) string
     */
    function monthAsString(uint256 idx) internal pure returns (string memory) {
        require(idx > 0, "bad idx");
        bytes memory str = new bytes(3);
        uint256 offset = (idx - 1) * 3;
        str[0] = bytes1(MONTHS[offset]);
        str[1] = bytes1(MONTHS[offset + 1]);
        str[2] = bytes1(MONTHS[offset + 2]);
        return string(str);
    }

    /**
     *   @dev returns string representation of number left-padded for 2 symbols
     */
    function asPaddedString(uint256 n) internal pure returns (string memory) {
        if (n == 0) return "00";
        if (n < 10) return string.concat("0", n.toString());
        return n.toString();
    }

    /**
     *   @dev returns string of format 'Jan 01, 2022 18:00 UTC' for a given timestamp
     */
    function asString(uint256 ts) external pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, ) = BokkyPooBahsDateTimeLibrary
            .timestampToDateTime(ts);
        return
            string(
                abi.encodePacked(
                    monthAsString(month),
                    " ",
                    day.toString(),
                    ", ",
                    year.toString(),
                    " ",
                    asPaddedString(hour),
                    ":",
                    asPaddedString(minute),
                    " UTC"
                )
            );
    }

    /**
     *   @dev returns (year, month as string) components of a date by timestamp
     */
    function yearAndMonth(uint256 ts) external pure returns (uint256, string memory) {
        (uint256 year, uint256 month, , , , ) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(ts);
        return (year, monthAsString(month));
    }
}