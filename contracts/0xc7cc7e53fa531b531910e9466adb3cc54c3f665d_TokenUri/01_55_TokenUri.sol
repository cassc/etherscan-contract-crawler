// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Wheyfu} from "./Wheyfu.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "base64/base64.sol";
import {svg} from "hot-chain-svg/SVG.sol";

contract TokenUri {
    string[] public colors = ["#CDB4DB", "#FFC8DD", "#FFAFCC", "#BDE0FE", "#A2D2FF"];

    string[] public texts = [
        "cant touch this!",
        "uwuwuuwuwuwuuwuw",
        "dyel?" "rip zyzz huhuhhe",
        "wow ur muscles are so big!",
        "lookin juicy",
        "mmmmm",
        "LISTEN im gunna crush this watermelon between my legs!",
        "*kisses*",
        "i love you so much",
        "watch me flex HEHEHHE",
        "do u mind if i take ur protein?",
        "dont even think about it!",
        "your mine now",
        "i just wanna be happy AAAAAAA",
        "*whispers* teehee",
        "gosh i love lifting so much",
        "u think ur bigger than me?",
        "anavar? never heard of it",
        "call me a varbie ONE more time! I DARE U",
        "lmao @ girls who do yoga",
        "EEK",
        "YOGA PANTS!?>@",
        "wowieeeeee ur so strong (not as strong as me thoughh ;_;)",
        "money or weights? idc as long as i have YOU xx",
        "gunna make it. srs. YOU are GOINHG TO MAKE IT !!",
        "UwU",
        "OwO",
        ":3 :3 :3",
        "autism is literally not real. pure psyop",
        "hope ur supping vit d and zinc!",
        "remember to drink water!!",
        "nofap x nomattress x nosugar -> BEST COMBO",
        "hmph!",
        "gosh im so sweaty!",
        "every day is leg day ;)",
        "can you spot me pls! it's my first time",
        "that's not fair! you're so much bigger than me!",
        "time for a water break!",
        "it's sooooo hot in here",
        "you don't mind if I hop in this set do you ;-;",
        "ummmm im just here to work out!"
    ];

    Wheyfu public wheyfu;

    constructor(address payable _wheyfu) {
        wheyfu = Wheyfu(_wheyfu);
    }

    function addressToString(address account) public pure returns (string memory) {
        bytes memory data = abi.encodePacked(account);

        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + (data.length << 1));
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + (i << 1)] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + (i << 1)] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }

        return string(str);
    }

    function renderSvg(uint256 tokenId) public view returns (string memory) {
        bytes32 colorSeed = keccak256(abi.encode(tokenId));
        string memory color = colors[uint256(colorSeed) % colors.length];

        bytes32 textSeed = keccak256(abi.encode(tokenId, 33333));
        string memory text = texts[uint256(textSeed) % texts.length];

        return string.concat(
            /* solhint-disable quotes */
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background:', color, '">'
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "10"), svg.prop("y", "20"), svg.prop("font-size", "14"), svg.prop("fill", "white")
                ),
                text
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "10"), svg.prop("y", "40"), svg.prop("font-size", "14"), svg.prop("fill", "white")
                ),
                "I'm not yet revealed :3"
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "10"), svg.prop("y", "60"), svg.prop("font-size", "14"), svg.prop("fill", "white")
                ),
                string.concat("my wholly unique identifier is #", Strings.toString(tokenId))
            ),
            "</svg>"
        );
        /* solhint-enable quotes */
    }

    function renderCallOptionSvg(uint256 tokenId) public view returns (string memory) {
        return string.concat(
            /* solhint-disable quotes */
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background:', "pink", '">'
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "10"), svg.prop("y", "20"), svg.prop("font-size", "16"), svg.prop("fill", "white")
                ),
                string.concat("Fresh: Ticket for ", Strings.toString(type(uint256).max - tokenId), " wheyfus")
            ),
            "</svg>"
        );
        /* solhint-enable quotes */
    }

    function renderJson(uint256 tokenId) public view returns (string memory) {
        string memory svgStr = tokenId <= wheyfu.MAX_SUPPLY() ? renderSvg(tokenId) : renderCallOptionSvg(tokenId);

        string memory json = string.concat(
            /* solhint-disable quotes */
            '{"name":"',
            "Wheyfus anonymous :3",
            '","description":"',
            "a group of very aesthetic <ppl>",
            '","image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svgStr)),
            '","attributes": [',
            "]}"
        );
        /* solhint-enable quotes */

        return json;
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        string memory jsonStr = renderJson(id);

        return string.concat("data:application/json;base64,", Base64.encode(bytes(jsonStr)));
    }
}