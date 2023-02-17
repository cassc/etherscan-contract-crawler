// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @notice ERC721 token with on-chain generative art.
 * @author Ryan Ghods (ralxz.eth)
 */
contract ArtToken is ERC721A, Ownable {
    /**
     * @notice Store the int representation of this address as a
     *         seed for its tokens' randomized output.
     */
    uint160 private immutable thisUintAddress = uint160(address(this));

    /**
     * @notice Deploy the token contract with its name and symbol.
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {
        _mintERC2309(msg.sender, 10);
        _mintERC2309(0x1108f964b384f1dCDa03658B24310ccBc48E226F, 20);
    }

    /**
     * @notice Emits an ERC721 `Transfer` event per mint.
     */
    function safeMint(address to, uint256 quantity) public onlyOwner {
        _safeMint(to, quantity);
    }

    /**
     * @notice Emits only one ERC2309 `ConsecutiveTransfer` event.
     *         This deviates from the ERC721 standard that requires
     *         a `Transfer` event per mint.
     */
    function batchMint(address to, uint256 quantity) public onlyOwner {
        _mintERC2309(to, quantity);
    }

    /**
     * @notice Returns the token URI for the token id.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return _tokenJson(tokenId);
    }

    /**
     * @notice Returns the json for the token id.
     */
    function _tokenJson(uint256 tokenId) internal view returns (string memory) {
        string memory svg;

        string memory rect = _randomRect(tokenId);
        string memory poly = _randomPolygon(tokenId);
        string memory circle = _randomCircle(tokenId);

        svg = string.concat(
            svg,
            "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'>"
            "<rect width='100%' height='100%' style='fill:",
            _randomColor(tokenId, true),
            "' /><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' style='fill:",
            _randomColor(tokenId + 1, false),
            ";font-family:",
            _font(tokenId),
            ";font-size:",
            _fontSize(tokenId),
            "px;",
            _randomStyle(tokenId, 1),
            "'>",
            Strings.toString(tokenId),
            "</text>",
            rect,
            poly,
            circle,
            "</svg>"
        );

        string memory json = '{"name": "#';

        json = string.concat(json, Strings.toString(tokenId),
            '", "description": "This is an example test token, for trying out cool things related to NFTs :)'
            ' Please note that this token has no value or warranty of any kind.\\n\\n\\"The future'
            ' belongs to those who believe in the beauty of their dreams.\\"\\n-Eleanor Roosevelt", "image_data": "',
         svg,
            '", "attributes": [ {"trait_type": "Token ID", "value": "',
            Strings.toString(tokenId),
            '"}, {"trait_type": "Font", "value": "',
            _font(tokenId),
            '"}, {"trait_type": "Font size", "value": "',
            _fontSize(tokenId),
            '"}, {"trait_type": "Rectangle", "value": "',
         _returnYesOrNo(rect),
         '"}, {"trait_type": "Triangle", "value": "',
          _returnYesOrNo(poly),
         '"}, {"trait_type": "Circle", "value": "',
         _returnYesOrNo(circle),
         '"}, {"trait_type": "Chain ID", "value": "',
         Strings.toString(block.chainid),
         '"}]}');

        return string.concat("data:application/json;utf8,", json);
    }

    /**
     * @notice Returns "No" if the input string is empty, otherwise "Yes",
     *         for formatting metadata traits.
     */
    function _returnYesOrNo(string memory input)
        internal
        pure
        returns (string memory)
    {
        return bytes(input).length == 0 ? "No" : "Yes";
    }

    /**
     * @notice Returns a random web safe font based on the token id.
     */
    function _font(uint256 tokenId) internal view returns (string memory) {
        uint256 roll = (thisUintAddress / tokenId) >> 1;
        if (roll % 13 == 0) {
            return "Courier New";
        } else if (roll % 9 == 0) {
            return "Garamond";
        } else if (roll % 8 == 0) {
            return "Tahoma";
        } else if (roll % 7 == 0) {
            return "Trebuchet MS";
        } else if (roll % 6 == 0) {
            return "Times New Roman";
        } else if (roll % 5 == 0) {
            return "Georgia";
        } else if (roll % 4 == 0) {
            return "Helvetica";
        } else {
            return "Brush Script MT";
        }
    }

    /**
     * @notice Returns a random font size based on the token id.
     */
    function _fontSize(uint256 tokenId) internal view returns (string memory) {
        uint256 roll = (thisUintAddress / tokenId) >> 2;
        return Strings.toString((roll % 180) + 12);
    }

    /**
     * @notice Returns a random color based on the token id.
     */
    function _randomColor(uint256 tokenId, bool onlyPastel)
        internal
        view
        returns (string memory)
    {
        uint256 roll = (thisUintAddress / tokenId) >> 3;
        string memory color = "rgb(";
        uint256 pastelBase = onlyPastel == true ? 127 : 0;
        uint256 r = ((roll >> 1) % (255 - pastelBase)) + pastelBase;
        uint256 g = ((roll >> 2) % (255 - pastelBase)) + pastelBase;
        uint256 b = ((roll >> 3) % (255 - pastelBase)) + pastelBase;
        color = string.concat(color, Strings.toString(r),
        ", ",
      Strings.toString(g),
        ", ",
     Strings.toString(b),
     ")");
        return color;
    }

    /**
     * @notice Returns a random rectangle...sometimes.
     */
    function _randomRect(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 roll = (thisUintAddress / tokenId) >> 4;
        if (roll % 3 != 0) return "";
        string memory rect = "<rect x='";
        uint256 x = (roll >> 1) % 301;
        uint256 y = (roll >> 2) % 302;
        uint256 width = (roll >> 3) % 303;
        uint256 height = (roll >> 4) % 303;
        rect = string.concat(rect, Strings.toString(x),
         "' y='",
         Strings.toString(y),
         "' width='",
         Strings.toString(width),
         "' height='",
         Strings.toString(height),
         "' style='",
         _randomStyle(tokenId, 3),
         "' />");
        return rect;
    }

    /**
     * @notice Returns a random polygon...sometimes.
     */
    function _randomPolygon(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 roll = (thisUintAddress / tokenId) >> 5;
        if (roll % 5 != 0) return "";
        string memory poly = "<polygon points='";
        uint256 x1 = (roll >> 1) % 301;
        uint256 y1 = (roll >> 2) % 302;
        uint256 x2 = (roll >> 3) % 303;
        uint256 y2 = (roll >> 4) % 304;
        uint256 x3 = (roll >> 5) % 305;
        uint256 y3 = (roll >> 6) % 306;
        poly = string.concat(poly, Strings.toString(x1), ",", Strings.toString(y1), " ", Strings.toString(x2), ",", Strings.toString(y2), " ", Strings.toString(x3), ",", Strings.toString(y3));
        poly = string.concat("' style='", _randomStyle(tokenId, 5), "' />");
        return poly;
    }

    /**
     * @notice Returns a random circle...sometimes.
     */
    function _randomCircle(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 roll = (thisUintAddress / tokenId) >> 6;
        if (roll % 7 != 0) return "";
        string memory circle = "<circle cx='";
        uint256 cx = (roll >> 1) % 300;
        uint256 cy = (roll >> 2) % 300;
        uint256 r = (roll >> 3) % 150;
        circle = string.concat(circle, Strings.toString(cx), "' cy='", Strings.toString(cy), "' r='", Strings.toString(r), "' style='", _randomStyle(tokenId, 7), "' />");
        return circle;
    }

    /**
     * @notice Returns a random style of fill color, fill opacity,
     *         stroke width, stroke opacity, and dasharray.
     */
    function _randomStyle(uint256 tokenId, uint256 seed)
        internal
        view
        returns (string memory)
    {
        string memory style = "fill:";
        style = string.concat(style, _randomColor(tokenId + seed + 1, true), ";fill-opacity:.", Strings.toString(_randomOpacity(tokenId + seed + 3)));
        if (((tokenId + seed) * 3) % 4 == 0) {
            style = string.concat(style, ";stroke:", _randomColor(tokenId + seed + 5, false), ";stroke-width:", Strings.toString(_randomStrokeWidth(tokenId + seed + 7)), ";stroke-opacity:.", Strings.toString(_randomOpacity(tokenId + seed + 9)));
            if ((tokenId + seed) % 5 == 0) {
                style = string.concat(style, ";stroke-dasharray:", Strings.toString(_randomStrokeWidth(tokenId + seed + 13)));
            }
        }
        return style;
    }

    /**
     * @notice Returns a random fill opacity from 1 to 9,
     *         to be prepended with a decimal in the css.
     */
    function _randomOpacity(uint256 tokenId) internal view returns (uint256) {
        uint256 roll = (thisUintAddress / tokenId) >> 3;
        return (roll % 9) + 1;
    }

    /**
     * @notice Returns a random stroke width from 0 to 9.
     */
    function _randomStrokeWidth(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 roll = (thisUintAddress / tokenId) >> 4;
        return roll % 10;
    }

    /**
     * @dev Overrides the `_startTokenId` function from ERC721A
     *      to start at token id `1`.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}