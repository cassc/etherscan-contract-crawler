// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./DateUtils.sol";
import "./UriEncode.sol";

string constant description = "Carlos Marcial's artwork marries the real and hyperreal, alluding to Jean Baudrillard's theories of simulacrum and hyperreality. Using AI, he conducts a dialogue with a digital version of Jean-Michel Basquiat, presenting an imitation with no original.\\n\\nThis artwork, modeled on an 80s photograph, crafts a non-existent moment, intertwining reality and representation. Marcial highlights his solitary role in creating this illusion, merging AI and human creativity in a post-truth era that redefines art.\\n\\nConcisely, this piece urges us to reassess our perceptions and acknowledge the role of AI in reimagining art.\\n\\nTechnology: this collection is composed of True Phygital NFTs powered by Causality, a middleware for phygital connections. The NFTs can be autographed in real life, only by the artist, using a physical item he carries on his person. For more information, see: https://causality.xyz/";

library OnChainMetadata {
    using Strings for uint256;
    using DateUtils for uint256;
    using UriEncode for string;

    function paddedString(string memory s) internal pure returns(string memory) {
        if (bytes(s).length == 1) {
            return string(abi.encodePacked("0", s));
        }
        return s;
    }

    function monthName(uint256 month) internal pure returns(string memory) {
        string[12] memory MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        unchecked {
            return MONTHS[month - 1];
        }
    }

    function dateOrdinal(uint256 day) internal pure returns(string memory) {
        if (day == 1 || day == 21 || day == 31) {
            return string(
                abi.encodePacked(
                    day.toString(),
                    "st"
                )
            );
        }
        if (day == 2 || day == 22) {
            return string(
                abi.encodePacked(
                    day.toString(),
                    "nd"
                )
            );
        }
        if (day == 3 || day == 23) {
            return string(
                abi.encodePacked(
                    day.toString(),
                    "rd"
                )
            );
        }
        return string(
            abi.encodePacked(
                day.toString(),
                "th"
            )
        );
    }

    function formattedDate(uint256 year, uint256 month, uint256 day) internal pure returns (string memory) {
        return string(abi.encodePacked(monthName(month), " ", dateOrdinal(day), " ", year.toString()));
    }

    function formattedTime(uint256 hour, uint256 minute, uint256 second) internal pure returns (string memory) {
        return string(abi.encodePacked(paddedString(hour.toString()), ":", paddedString(minute.toString()), ":", paddedString(second.toString())));
    }

    function unsignedTokenURI(uint256 tokenId, string memory image, string memory webapp) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                'data:application/json,{"name":"Artist in a Post-Truth World  #',
                tokenId.toString(),
                '","description":"',
                description,
                '","image":"',
                image,
                '","animation_url":"',
                webapp,
                '?id=',
                tokenId.toString(),
                '","attributes":[{"trait_type":"Signed","value": "No"}]}'
            )
        ).uriEncode();
    }

    function signedTokenURI(uint256 tokenId, uint256 timestamp, string memory image) internal pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) = timestamp.toDateTime();
        return string(
            abi.encodePacked(
                'data:application/json,{"name":"Artist in a Post-Truth World #',
                tokenId.toString(),
                ' (Signed)","description":"',
                description,
                '","image":"',
                image,
                '","attributes":[{"trait_type":"Signed","value": "Yes"},{"trait_type":"Autograph Date","value":"',
                formattedDate(year, month, day),
                '"},{"trait_type":"Autograph Time","value":"',
                formattedTime(hour, minute, second),
                '"},{"trait_type":"Autograph","display_type":"date","value":',
                timestamp.toString(),
                '}]}'
            )
        ).uriEncode();
    }

}