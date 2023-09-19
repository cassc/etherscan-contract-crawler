// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Base64} from "openzeppelin/utils/Base64.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import "solady/utils/SSTORE2.sol";
import "openzeppelin/utils/Strings.sol";

interface IToken {
    function seed(uint256 tokenID) external view returns (bytes32);
}

contract CoinRenderer is Ownable {
    using Strings for uint256;

    address public svg;

    constructor(address _svg) {
        svg = _svg;
        _initializeOwner(tx.origin);
    }

    struct Coin {
        uint256 rotateSpeed;
        uint256 rotateDirection;
        uint256 borderSize;
        uint256 bgAngle;
        uint256 angle;
        uint256 color;
        uint256 gradType;
        uint256 gradStops;
        string colorsCSS;
        string borderColorsCSS;
    }

    function _renderAttributes(Coin memory coin) internal pure returns (string memory) {
        string[] memory keys = new string[](6);
        string[] memory values = new string[](6);
        keys[0] = "Speed";
        values[0] = string.concat(coin.rotateSpeed.toString(), "s");

        keys[1] = "Spin";
        if (coin.rotateDirection == 0) {
            values[1] = "Clockwise";
        } else {
            values[1] = "Counter-clockwise";
        }

        keys[2] = "Thickness";
        values[2] = string.concat(coin.borderSize.toString(), "px");

        keys[3] = "Material";
        if (coin.color == 0) {
            values[3] = "Gold";
        } else if (coin.color == 1) {
            values[3] = "Silver";
        } else if (coin.color == 2) {
            values[3] = "Bronze";
        } else if (coin.color == 3) {
            values[3] = "Hyperlink Blue";
        } else if (coin.color == 4) {
            values[3] = "Void";
        }

        keys[4] = "Polish";
        values[4] = coin.gradType == 0 ? "Conic" : "Linear";

        keys[5] = "Reflection";
        values[5] = coin.gradStops.toString();

        string memory attributes = "[";
        string memory separator = ",";

        for (uint256 i = 0; i < keys.length; i++) {
            if (i == keys.length - 1) {
                separator = "]";
            }

            attributes = string(
                abi.encodePacked(
                    attributes, "{\"trait_type\": \"", keys[i], "\", \"value\": \"", values[i], "\"}", separator
                )
            );
        }

        return attributes;
    }

    function _blueColor(bytes32 seed, uint256 nonce) internal pure returns (string memory) {
        return string.concat("rgb(0,", random(seed, nonce, 0, 250).toString(), ", 255)");
    }

    string[5] private _gold = ["#fff8c9", "#f1e577", "#f7efad", "#b27018", "#ffffff"];
    string[7] private _silver = ["#ffffff", "#eeeeee", "#cccece", "#abaaaa", "#888888", "#686666", "#444848"];
    string[4] private _bronze = ["#DDB288", "#4F2E23", "#986044", "#ffffff"];
    string[7] private _void = ["#ffffff", "#000000", "#050505", "#101010", "#151515", "#202020", "#252525"];

    function _deriveColors(
        bytes32 seed,
        uint256 nonce,
        uint256 gradStops,
        uint256 gradType,
        uint256 angle,
        uint256 color
    ) internal view returns (string memory) {
        string[10] memory colors;
        nonce = nonce + angle;

        if (color == 0) {
            colors[0] = _gold[0];
            for (uint256 i = 1; i < gradStops; i++) {
                colors[i] = _gold[random(seed, nonce++, 1, _gold.length - 1)];
            }
        } else if (color == 1) {
            colors[0] = _silver[0];
            for (uint256 i = 1; i < gradStops; i++) {
                colors[i] = _silver[random(seed, nonce++, 1, _silver.length - 1)];
            }
        } else if (color == 2) {
            colors[0] = _bronze[0];
            for (uint256 i = 1; i < gradStops; i++) {
                colors[i] = _bronze[random(seed, nonce++, 1, _bronze.length - 1)];
            }
        } else if (color == 3) {
            colors[0] = "#ffffff";
            for (uint256 i = 1; i < gradStops; i++) {
                colors[i] = _blueColor(seed, nonce++);
            }
        } else if (color == 4) {
            colors[0] = _void[0];
            for (uint256 i = 1; i < gradStops; i++) {
                colors[i] = _void[random(seed, nonce++, 1, _void.length - 1)];
            }
        }

        string memory gCSS;

        if (gradType == 0) {
            gCSS = string.concat("conic-gradient(from ", angle.toString(), "deg at 50% 50%, ");
        } else {
            gCSS = string.concat("linear-gradient(", angle.toString(), "deg, ");
        }

        gCSS = string.concat(gCSS, colors[0], " 0%, ");

        for (uint256 i = 1; i < gradStops; i++) {
            gCSS = string.concat(gCSS, colors[i], " ", (i * 100 / gradStops).toString(), "%, ");
        }

        gCSS = string.concat(gCSS, colors[0], " 100%)");

        return gCSS;
    }

    function _pickColor(bytes32 seed, uint256 nonce) internal pure returns (uint256) {
        uint256 colorSeed = random(seed, nonce++, 1, 100);
        if (colorSeed <= 40) {
            return 2; // 40% bronze
        } else if (colorSeed <= 70) {
            return 1; // 30% silver
        } else if (colorSeed <= 90) {
            return 0; // 20% gold
        } else if (colorSeed <= 99) {
            return 3; // 9% hyperlink blue
        } else {
            return 4; // 1% void
        }
    }

    function deriveCoin(bytes32 seed) public view returns (Coin memory) {
        uint256 nonce;

        uint256 rotateSpeed = random(seed, nonce++, 1, 11);
        uint256 rotateDirection = random(seed, nonce++, 0, 1); // 0 = clockwise, 1 = counter-clockwise
        uint256 borderSize = random(seed, nonce++, 5, 15);
        uint256 bgAngle = random(seed, nonce++, 0, 360);
        uint256 angle = random(seed, nonce++, 0, 360);
        uint256 borderAngle = random(seed, nonce++, 0, 360);
        uint256 color = _pickColor(seed, nonce++);
        uint256 gradType = random(seed, nonce++, 0, 1); // 0 = conic, 1 = linear
        uint256 gradStops = 4 + random(seed, nonce++, 0, 3) * 2; // gradient stops, 4, 6, 8 or 10
        uint256 borderGradStops = 4 + random(seed, nonce++, 0, 3) * 2;

        string memory colors = _deriveColors(seed, 11, gradStops, gradType, angle, color);
        string memory borderColors = _deriveColors(seed, 12, borderGradStops, borderAngle, 1, color);

        return Coin(
            rotateSpeed, rotateDirection, borderSize, bgAngle, angle, color, gradType, gradStops, colors, borderColors
        );
    }

    function generateCSS(Coin memory c) public pure returns (string memory) {
        string memory bgCSS = string.concat("linear-gradient(", c.bgAngle.toString(), "deg, ");
        if (c.color == 0) {
            bgCSS = string.concat(bgCSS, "#4a320c 0%, #b27018 100%);");
        } else if (c.color == 1) {
            bgCSS = string.concat(bgCSS, "#222 0%, #777 100%);");
        } else if (c.color == 2) {
            bgCSS = string.concat(bgCSS, "#4F2E23 0%, #291a15 100%);");
        } else if (c.color == 3) {
            bgCSS = string.concat(bgCSS, "#000096 0%, #0000f3 100%);");
        } else if (c.color == 4) {
            bgCSS = string.concat(bgCSS, "#111111 0%, #222222 100%);");
        }

        string memory cBG =
            string.concat(c.colorsCSS, " content-box content-box, ", c.borderColorsCSS, " border-box border-box;");
        return string.concat(
            "<style>:root{--cg: ",
            cBG,
            "--bg: ",
            bgCSS,
            "--a: ",
            c.rotateSpeed.toString(),
            "s;",
            "--r:",
            c.rotateDirection == 0 ? "cc;" : "ccw;",
            "--bor:",
            c.borderSize.toString(),
            "px;}</style></svg>"
        );
    }

    function random(bytes32 seed, uint256 nonce, uint256 min, uint256 max) public pure returns (uint256) {
        unchecked {
            return uint256(keccak256(abi.encodePacked(seed, nonce))) % (max - min + 1) + min;
        }
    }

    function tokenURIJSON(uint256 id) public view returns (string memory) {
        bytes32 seed = IToken(msg.sender).seed(id);
        Coin memory coin = deriveCoin(seed);

        return string(
            abi.encodePacked(
                "{",
                '"name": "Coin #',
                Strings.toString(id),
                '",',
                '"image": "data:image/svg+xml;base64,',
                renderCoin(coin),
                '","attributes":',
                _renderAttributes(coin),
                "}"
            )
        );
    }

    function renderCoin(Coin memory c) public view returns (string memory) {
        bytes memory coin = SSTORE2.read(svg);
        return string(Base64.encode(abi.encodePacked(coin, generateCSS(c))));
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        string memory json = Base64.encode(bytes(tokenURIJSON(id)));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}