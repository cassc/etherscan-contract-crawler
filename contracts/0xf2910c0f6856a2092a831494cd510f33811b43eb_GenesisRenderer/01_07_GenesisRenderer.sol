//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/access/Ownable.sol";

import {Base64} from "solady/utils/Base64.sol";
import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {LibString} from "solady/utils/LibString.sol";

import "./ISpaceFont.sol";

/// @title On-chain renderer for POS NFT
/// @author @0x_beans
contract GenesisRenderer is Ownable {
    // index where the gradient image is stored
    uint256 public constant GRADIENT = 0;

    // mapping to store the gradient
    mapping(uint256 => address) public files;

    // we pass in tokenID even though we don't use it
    // in case we need it when we upgrade renderers
    function tokenURI(
        uint256 tokenId,
        uint256 blockNumber,
        uint256 mergeBlock
    ) external view returns (string memory svgString) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{"
                            '"name": "Sunrise",',
                            '"description": "An attempt to be the first on-chain NFT to be minted on POS",'
                            '"image": "data:image/svg+xml;base64,',
                            Base64.encode(bytes(getSVG(blockNumber))),
                            '",'
                            '"attributes": [{"trait_type": "block number", "value":"',
                            LibString.toString(blockNumber),
                            '"},',
                            '{"trait_type": "merge block number", "value":"',
                            LibString.toString(mergeBlock),
                            '"}]}'
                        )
                    )
                )
            );
    }

    // construct image
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
                "fill: black;"
                "}"
                "</style>"
                "</svg>"
            )
        );
    }

    // on chain font
    address public spaceFont;

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