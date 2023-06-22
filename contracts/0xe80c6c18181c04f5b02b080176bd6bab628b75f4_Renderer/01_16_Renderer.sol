// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {IRenderer} from "./interfaces/IRenderer.sol";
import {IProofOfVisit} from "./interfaces/IProofOfVisit.sol";
import {Util} from "./Util.sol";

contract Renderer is IRenderer, Ownable, Util {
    string public imageBaseUrl;
    string public imageUrlSuffix;
    string public dataBaseUrl;
    string public scriptPath;
    string public cssPath;

    constructor(string memory _imageBaseUrl, string memory _imageUrlSuffix, string memory _dataBaseUrl) {
        imageBaseUrl = _imageBaseUrl;
        imageUrlSuffix = _imageUrlSuffix;
        dataBaseUrl = _dataBaseUrl;
        scriptPath = "js/mainvisual.js";
        cssPath = "css/mainvisual.css";
    }

    function setImageUrl(string memory url, string memory suffix) external onlyOwner {
        imageBaseUrl = url;
        imageUrlSuffix = suffix;
    }

    function setDataUrl(string memory _dataBaseUrl, string memory _scriptPath, string memory _cssPath) external onlyOwner {
        dataBaseUrl = _dataBaseUrl;
        scriptPath = _scriptPath;
        cssPath = _cssPath;
    }

    function imageUrl(uint256 tokenId) external view returns (string memory) {
        return string.concat(imageBaseUrl, Strings.toString(tokenId), imageUrlSuffix);
    }

    function animationUrl(uint256 /* tokenId */, IProofOfVisit.TokenAttribute memory tokenAttribute) external view returns (string memory) {
        string memory imageData = string.concat(
            "<!DOCTYPE html>",
            '<html lang="en">',
            "<head>",
            '<meta charset="UTF-8">',
            '<meta name="viewport" content="width=device-width, initial-scale=0.5">',
            "<title>PROOF OF X</title>",
            '\n<script type="text/javascript">\n',
            "var attribute = {\n",
            '  hash: "0x', bytes32ToString(tokenAttribute.seed), '",\n',
            '  name: "', getName(tokenAttribute.name), '",\n',
            '  role: "', tokenAttribute.role, '",\n',
            '  mintedAt: ', Strings.toString(uint256(tokenAttribute.mintedAt)), "\n",
            "}\n",
            "</script>\n",
            '<style type="text/css">body { margin: 0; padding: 0; background-color: #000; font-family: Helvetica, Arial, sans-serif; overflow: hidden; }</style>',
            '<link rel="stylesheet" href="', dataBaseUrl, cssPath, '">',
            "</head>",
            "<body>",
            '<script type="text/javascript" src="', dataBaseUrl, scriptPath, '" id="mainvisual_js" data-mode="nft" data-baseurl="', dataBaseUrl, '"></script>',
            '<div id="mainvisual_title"></div>',
            '<div class="mainvisual_container">',
            '<canvas id="mainvisual_webgl"></canvas>',
            '</div>',
            "</body>",
            "</html>"
        );
        return string.concat("data:text/html;charset=UTF-8;base64,", Base64.encode(bytes(imageData)));
    }

    function getName(string memory name) private pure returns (string memory) {
        if (bytes(name).length == 0) {
            return "Anonymous";
        }
        return escapeString(name);
    }
}