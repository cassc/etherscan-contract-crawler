// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title: Proof of Merge - ASCII Generator
/// @author: x0r (Michael Blau) and Mason Hall

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IASCIIGenerator} from "./IASCIIGenerator.sol";

contract ASCIIGenerator is Ownable, IASCIIGenerator {
    using Base64 for string;
    using Strings for uint256;

    uint256[][] public imagePhases;
    uint256 public phaseTwoStart;

    string internal description =
        "Proof of Merge is a fully on-chain, non-transferable, and dynamic NFT that will change throughout The Merge. We detect The Merge on-chain by checking if the DIFFICULTY opcode returns 0 according to EIP3675. During The Merge, the current Ethereum execution layer will merge into the Beacon chain, and Ethereum will transition from Proof of Work to Proof of Stake. Proof of Merge is a collaboration between Michael Blau (x0r) and Mason Hall.";
    string internal SVGHeader =
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 720 802'><defs><style>.cls-1{font-size: 10px; fill: white; font-family:monospace;}</style></defs><g><rect width='720' height='802' fill='black' />";
    string internal firstTextTagPart =
        "<text lengthAdjust='spacing' textLength='720' class='cls-1' x='0' y='";
    string internal SVGFooter = "</g></svg>";
    uint256 internal tspanLineHeight = 12;

    constructor(uint256 _phaseTwoStart) {
        phaseTwoStart = _phaseTwoStart;
    }

    // =================== ASCII GENERATOR FUNCTIONS =================== //

    /**
     * @notice Generate full NFT metadata
     */
    function generateMetadata() external view returns (string memory) {
        string memory SVG = generateSVG();

        string memory metadata = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "Proof of Merge","description":"',
                    description,
                    '","image":"',
                    SVG,
                    '"}'
                )
            )
        );

        return string.concat("data:application/json;base64,", metadata);
    }

    /**
     * @notice Generate the SVG ASCII image
     */
    function generateSVG() public view returns (string memory) {
        string[66] memory rows = genCoreAscii();

        string memory _firstTextTagPart = firstTextTagPart;
        string memory span;
        string memory center;
        uint256 y = tspanLineHeight;

        for (uint256 i; i < rows.length; i++) {
            span = string.concat(
                _firstTextTagPart,
                y.toString(),
                "'>",
                rows[i],
                "</text>"
            );
            center = string.concat(center, span);
            y += tspanLineHeight;
        }

        // base64 encode the SVG
        string memory SVGImage = Base64.encode(
            bytes(string.concat(SVGHeader, center, SVGFooter))
        );

        return string.concat("data:image/svg+xml;base64,", SVGImage);
    }

    /**
     * @notice Generate all ASCII rows of the image as strings
     */
    function genCoreAscii() public view returns (string[66] memory) {
        string[66] memory asciiRows;

        uint256[] memory imageRows = imagePhases[determineArtPhase()];

        for (uint256 i; i < asciiRows.length; i++) {
            asciiRows[i] = rowToString(imageRows[i], 120);
        }

        return asciiRows;
    }

    /**
     * @notice Generate one ASCII row as a string
     */
    function rowToString(uint256 _row, uint256 _bitsToUnpack)
        internal
        pure
        returns (string memory)
    {
        string memory rowString;

        for (uint256 i; i < _bitsToUnpack; i++) {
            if (((_row >> (1 * i)) & 1) == 0) {
                rowString = string.concat(rowString, ".");
            } else {
                rowString = string.concat(rowString, "1");
            }
        }

        return rowString;
    }

    // =================== MERGE FUNCTIONS =================== //

    function determineArtPhase() public view returns (uint256) {
        if (block.difficulty > 2**64 || block.difficulty == 0) {
            return 2;
        } else if (block.timestamp >= phaseTwoStart) {
            return 1;
        } else {
            return 0;
        }
    }

    // =================== STORE IMAGE DATA =================== //

    function storeImageParts(uint256[][] memory _imagePhases)
        external
        onlyOwner
    {
        imagePhases = _imagePhases;
    }

    function setSVGParts(
        string calldata _SVGHeader,
        string calldata _SVGFooter,
        string calldata _firstTextTagPart,
        uint256 _tspanLineHeight
    ) external onlyOwner {
        SVGHeader = _SVGHeader;
        SVGFooter = _SVGFooter;
        firstTextTagPart = _firstTextTagPart;
        tspanLineHeight = _tspanLineHeight;
    }

    function getSVGParts()
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint256
        )
    {
        return (SVGHeader, SVGFooter, firstTextTagPart, tspanLineHeight);
    }

    function setDescription(string calldata _description) external onlyOwner {
        description = _description;
    }

    function setPhaseTwoStartTime(uint256 _phaseTwoStart) external onlyOwner {
        phaseTwoStart = _phaseTwoStart;
    }
}