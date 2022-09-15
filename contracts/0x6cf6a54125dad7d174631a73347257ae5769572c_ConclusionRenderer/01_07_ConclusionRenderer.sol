//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/access/Ownable.sol";

import {Base64} from "solady/utils/Base64.sol";
import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {LibString} from "solady/utils/LibString.sol";

import "./ISpaceFont.sol";

/// @title On-chain renderer for POW NFT
/// @author @0x_beans
contract ConclusionRenderer is Ownable {
    // index of where the gradient image is tored
    uint256 public constant GRADIENT = 0;

    // mapping of where we'll store the gradient image
    mapping(uint256 => address) public files;

    // our on-chain font for rendering
    address public spaceFont;

    // we pass in tokenID even though we're not using it
    // in case our new renderer needs it
    function tokenURI(
        uint256 tokenId,
        uint256 blockNumber,
        uint256 blockDifficulty
    ) external view returns (string memory svgString) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{"
                            '"name": "Sunset",',
                            '"description": "An attempt to be the last on-chain NFT to be minted on POW",'
                            '"image": "data:image/svg+xml;base64,',
                            Base64.encode(bytes(getSVG(blockNumber))),
                            '",'
                            '"attributes": [{"trait_type": "block number", "value":"',
                            LibString.toString(blockNumber),
                            '"},',
                            '{"trait_type": "block difficulty", "value":"',
                            LibString.toString(blockDifficulty),
                            '"}]}'
                        )
                    )
                )
            );
    }

    // construct the image
    function getSVG(uint256 blockNumber)
        internal
        view
        returns (string memory svgString)
    {
        svgString = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' width='256' height='256' viewBox='0 0 256 256' preserveAspectRatio='none'>"
                "<image height='256' width='256' href='",
                string(SSTORE2.read(files[GRADIENT])),
                "'/>"
                "<text x='50%' y='40%' dominant-baseline='middle' text-anchor='middle' class='title'>"
                "MINTED"
                "</text>"
                "<text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' class='title'>"
                "AT"
                "</text>"
                "<text x='50%' y='60%' dominant-baseline='middle' text-anchor='middle' class='title'> #",
                LibString.toString(blockNumber),
                "</text>"
                "<style type='text/css'>"
                "@font-face {"
                "font-family: 'Space-Grotesk';"
                "font-style: normal;"
                "src:url(",
                ISpaceFont(spaceFont).getFont(),
                ");}"
                ".title {"
                "font-family: 'Space-Grotesk';"
                "letter-spacing: 0.025em;"
                "font-size: 23px;"
                "fill: white;"
                "}"
                "</style>"
                "</svg>"
            )
        );
    }

    function setFontContract(address font) external onlyOwner {
        spaceFont = font;
    }

    // save gradient on chain
    function saveFile(uint256 index, string calldata fileContent)
        public
        onlyOwner
    {
        files[index] = SSTORE2.write(bytes(fileContent));
    }
}