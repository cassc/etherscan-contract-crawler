// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";
import "./DateTimeLibrary.sol";
import "./NhlMetaDataGenerator.sol";

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NhlMetaDataGenerator {
    using Strings for uint256;

    struct Prediction {
        uint256 tokenId;
        address owner;
        string selection;
        uint256 timestamp;
        string _colorOne;
        string _colorTwo;
    }

    string public constant svgStart =
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 300 300"><defs> <linearGradient id="a" x1="150" x2="150" y2="300" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="';

    // in between these in the svg formatting, we put the gradient params

    string public constant svgMiddle =
        '<path d="M0 0h300v300H0z" fill="url(#a)"/><path d="M149 24a126 126 0 1 0 0 252 126 126 0 0 0 0-252Zm0 225.3a99.3 99.3 0 1 1 .1 0h-.1Z" fill="#000"/><path d="M148.6 214v1.5h.3l-.3-1.5Zm0 0-.1 1.5h-.4a50.8 50.8 0 0 1-5.4-.8c-3.5-.7-8.2-1.8-13.2-3.6-9.8-3.7-21-10.6-24.7-23a402 402 0 0 1-8.8-38.6 721.8 721.8 0 0 1-3.5-20.7v-.3l1.4-.3-1.4.2-.3-1.7h1.7l109-.3h1.8l-.3 1.8-1.5-.3 1.5.3v.4a495 495 0 0 1-1.2 6l-3.3 15.7a568 568 0 0 1-9.1 37.8c-3.3 11.2-14 18-23.5 22a88.6 88.6 0 0 1-18.3 5.4h-.1l-.3-1.5Z" fill="#A4A9AD" stroke="#000" stroke-width="3"/><path d="M149 104c-5.3-.1-9-.8-11.4-2.1a8.9 8.9 0 0 1-4.6-5.4c-.8-2.4-1-5.3-1-8.7l-.1-2.7c0-2.6 0-5.4-.3-8.4l34.5-.2v11c0 3.5-.2 6.5-1 9a9.1 9.1 0 0 1-4.7 5.5 25 25 0 0 1-11.4 2Z" fill="#D9D9D9" stroke="#5F5A5A"/><path d="m154.7 103.3.1 4.4h-11.1v-4.4c1.5-.5 2.8-.7 5.2-.8 2.8.2 4.2.4 5.8.8Z" fill="#D9D9D9" stroke="#5F5A5A"/><path d="m154.7 103.3.1 4.4h-11.1v-4.4c1.5-.5 2.8-.7 5.2-.8 2.8.2 4.2.4 5.8.8Z" fill="#D9D9D9" stroke="#5F5A5A"/><path d="m158.4 108.1.2 5h-19.5v-5a56.5 56.5 0 0 1 19.2 0Z" fill="#D9D9D9" stroke="#5F5A5A"/><path d="m161.3 114 .4 7.6H136v-7.7a65.5 65.5 0 0 1 25.2 0Z" fill="#D9D9D9" stroke="#5F5A5A"/><path d="m170.9 127.1.6 43.8H127v-43.8c3.2-2.7 5.5-4.6 8.5-5.8 3-1.2 6.6-1.8 12.3-1.8 6.6 0 10.7.7 14 2 3 1.3 5.5 3 8.5 5.2l.6.4Z" fill="#D9D9D9" stroke="#5F5A5A"/><path d="m174.6 169.8.7 13.5h-52.9v-13.5a115 115 0 0 1 24.8-2.5c13.2.5 19.5 1 27.4 2.5Z" fill="#D9D9D9" stroke="#5F5A5A"/><path d="M118.7 184c0-.7.3-1.5 1.2-2.6l57.3.2c.7 1.1 1 2 .9 2.8a6 6 0 0 1-1 2.7 396.1 396.1 0 0 1-56.4-.2c-1.3-1.2-1.9-2.1-2-2.9Z" fill="#989393" stroke="#5F5A5A"/><path d="m147.8 123 63 1.3c2 2-6 10.9-6 13.4 3.4 7.3 9 11.7 6.6 13.9-14.8 0-32.3-1-32.3 3.4-4.7 3.3.5 14.8-5.8 18 0 0-51 3-53.4-1.4-2.5-4.3 0-17.3-5.6-18l-23-2c-2-1.1-2.8-2.7-3.3-7.9v-13.5c.4-4 1.2-5.1 3.4-6l56.4-1.2Z" fill="#000"/><path d="M164.8 130.8c1 1 1.5 2.5 1.5 4.4 0 2-.5 3.5-1.5 4.6a6 6 0 0 1-4.3 1.5H157v5.7h-3.4v-17.8h6.9c1.8 0 3.3.5 4.3 1.6Zm-2 4.4c0-2-.8-2.9-2.5-2.9H157v5.9h3.3a3 3 0 0 0 1.9-.7c.4-.4.7-1.2.7-2.3Zm10 11.8h-3.5v-17.8h3.4V147Zm13-6.9h3.3c0 2.3-.6 4-1.7 5.2a6.2 6.2 0 0 1-4.8 1.8c-4.6 0-6.8-2.6-6.8-8v-1.5c0-4.2 1.1-6.8 3.5-7.9.9-.4 2-.6 3.3-.6 1.9 0 3.4.5 4.6 1.5 1.2 1 1.8 2.6 1.8 4.5h-3.2c-.2-1-.5-1.7-1-2.2a3 3 0 0 0-2.2-.8c-1.2 0-2 .4-2.6 1.2-.4.5-.6 1.3-.7 2.6v3.2c0 1.9.2 3.2.7 3.9.6.7 1.4 1 2.6 1 1.2 0 2-.3 2.4-.9a9 9 0 0 0 .9-3Zm14.3-2.5 6.1 9.4h-4l-4.2-6.7-2.5 3.2v3.5h-3.4v-17.8h3.4v10l6.8-10h3.5l-5.7 8.4Zm-91.9 2.5h3.2c0 2.3-.5 4-1.7 5.2a6.2 6.2 0 0 1-4.8 1.8c-4.5 0-6.8-2.6-6.8-8v-1.5c0-4.2 1.2-6.8 3.5-7.9 1-.4 2-.6 3.3-.6 2 0 3.5.5 4.7 1.5 1.2 1 1.8 2.6 1.8 4.5H108c-.2-1-.5-1.7-1-2.2-.4-.5-1.2-.8-2.2-.8a3 3 0 0 0-2.6 1.2c-.4.5-.6 1.3-.7 2.6v3.2c0 1.9.2 3.2.8 3.9.5.7 1.4 1 2.5 1 1.2 0 2-.3 2.4-.9a6 6 0 0 0 .9-3Zm19.3-10.9v11.7c0 2-.7 3.5-2 4.6a7.1 7.1 0 0 1-4.8 1.7c-2 0-3.6-.6-4.9-1.7a5.7 5.7 0 0 1-2-4.6v-11.7h3.5v11.6c0 1 .3 1.9 1 2.4.6.6 1.4.9 2.4.9s1.8-.3 2.4-.8c.6-.6 1-1.4 1-2.5v-11.6h3.4Zm14.8 1.6a6 6 0 0 1 1.6 4.4c0 2-.6 3.5-1.6 4.6-1 1-2.4 1.5-4.3 1.5h-3.4v5.7H131v-17.8h6.9c1.9 0 3.3.5 4.3 1.6Zm-2 4.4c0-2-.8-2.9-2.5-2.9h-3.2v5.9h3.2c.8 0 1.5-.3 2-.7.4-.4.6-1.2.6-2.3Zm-8.5 32.8H125a3 3 0 0 1-1.5-.4c-.4-.2-.6-.6-.6-1.2 0-.4.1-.9.5-1.3 0-.2.3-.4.6-.7l2.1-2.4a14.6 14.6 0 0 0 2.7-3.4l.3-1.2c0-.3-.1-.6-.4-1-.2-.3-.7-.4-1.3-.4-.7 0-1.1.2-1.4.5a3 3 0 0 0-.3 1.6H123l.1-1.7c.1-.5.3-1 .6-1.4.6-1 1.9-1.4 3.8-1.4a5 5 0 0 1 3.2.9c.8.6 1.1 1.4 1.1 2.5a5 5 0 0 1-.4 2c-.3.7-.6 1.3-1 1.7a34.5 34.5 0 0 1-2 2.3l-2.2 2.7h5.5v2.3Zm11 0h-6.9a3 3 0 0 1-1.5-.4c-.4-.2-.6-.6-.6-1.2 0-.4.2-.9.5-1.3l.6-.7 2.2-2.4a14.6 14.6 0 0 0 2.6-3.4l.4-1.2c0-.3-.2-.6-.4-1-.3-.3-.7-.4-1.4-.4-.6 0-1 .2-1.3.5a3 3 0 0 0-.4 1.6H134c0-.7 0-1.2.2-1.7 0-.5.3-1 .6-1.4.6-1 1.8-1.4 3.7-1.4 1.4 0 2.5.3 3.3.9.7.6 1 1.4 1 2.5 0 .6 0 1.3-.4 2-.3.7-.6 1.3-1 1.7a34.5 34.5 0 0 1-1.9 2.3l-2.2 2.7h5.5v2.3Zm8.4-4.5h-6.1v-2.4h6.2v2.4Zm11 4.5h-6.8a3 3 0 0 1-1.5-.4c-.4-.2-.6-.6-.6-1.2 0-.4.2-.9.5-1.3l.6-.7 2.1-2.4a14.6 14.6 0 0 0 2.7-3.4l.3-1.2c0-.3-.1-.6-.4-1-.2-.3-.6-.4-1.3-.4-.6 0-1 .2-1.3.5a3 3 0 0 0-.4 1.6h-2.6l.1-1.7.7-1.4c.6-1 1.8-1.4 3.7-1.4 1.4 0 2.5.3 3.2.9a3 3 0 0 1 1.2 2.5 7.5 7.5 0 0 1-1.4 3.7 35.3 35.3 0 0 1-2 2.3l-2.3 2.7h5.5v2.3Zm6-6.5.4-2.2 1.2.6a4 4 0 0 0 .8-2.5c0-.3-.2-.6-.5-.9a2 2 0 0 0-1.4-.5c-.7 0-1.1.2-1.4.5-.2.3-.3.8-.3 1.6h-2.5c0-1.5.4-2.6 1-3.4.8-.7 1.8-1 3.2-1 3 0 4.4 1.2 4.4 3.7 0 1.4-.4 2.6-1.3 3.5 1 .6 1.5 1.7 1.5 3.3 0 1.2-.4 2.2-1.2 2.9-.8.7-1.9 1-3.3 1s-2.5-.3-3.2-1c-.7-.8-1-1.8-1-3h2.5v.7l.5.6c.3.2.7.3 1.2.3.6 0 1-.1 1.4-.5.3-.3.5-.7.5-1.2 0-.4 0-.8-.3-1a10 10 0 0 0-.3-.5l-.5-.3a13 13 0 0 0-1.4-.7Z" fill="#E87917"/><path id="b" d="M32 150a118 118 0 1 0 236 0 118 118 0 1 0-236 0" fill="none"><animateTransform attributeName="transform" begin="0s" dur="50s" type="rotate" from="0 150 150" to="360 150 150" repeatCount="indefinite"/></path><text dy="0" font-size="9" font-family="Arial" font-weight="900" fill="#fff" letter-spacing=".75"><textPath xlink:href="#b">';

    function generateGradientString(Prediction memory params)
        public
        pure
        returns (string memory)
    {
        string memory gradientSVGCode = string(
            abi.encodePacked(
                params._colorOne,
                '" /><stop offset="1" stop-color="',
                params._colorTwo,
                '" /></linearGradient></defs>'
            )
        );

        return gradientSVGCode;
    }

    function generateTextString(Prediction memory params)
        public
        pure
        returns (string memory)
    {
        (uint256 year, uint256 month, uint256 day) = DateTimeLibrary
            .timestampToDate(params.timestamp);

        return
            string(
                abi.encodePacked(
                    "The ",
                    params.selection,
                    " will win the cup in 2023  /  Predicted by ",
                    Strings.toHexString(params.owner),
                    " on ",
                    month.toString(),
                    "-",
                    day.toString(),
                    "-",
                    year.toString(),
                    "</textPath></text></svg>" //team name
                )
            );
    }

    function generateSVGofTokenById(Prediction memory params)
        public
        pure
        returns (string memory)
    {
        string memory svg = string(
            abi.encodePacked(
                svgStart,
                generateGradientString(params),
                svgMiddle,
                generateTextString(params)
            )
        );

        return svg;
    }

    function tokenURI(Prediction memory params)
        public
        pure
        returns (string memory)
    {
        (uint256 year, uint256 month, uint256 day) = DateTimeLibrary
            .timestampToDate(params.timestamp);

        string memory name = string(
            abi.encodePacked("Prediction #", params.tokenId.toString())
        );

        string memory team = params.selection;

        string memory description = string(
            abi.encodePacked(
                Strings.toHexString(params.owner),
                " thinks that the ",
                params.selection,
                " will win the 2023 Stanley Cup. This prediction was made on ",
                month.toString(),
                "-",
                day.toString(),
                "-",
                year.toString(),
                "."
            )
        );

        string memory image = Base64.encode(
            bytes(generateSVGofTokenById(params))
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "predictor":"',
                                Strings.toHexString(params.owner),
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '", "attributes": [{ "trait_type": "Prediction Year", "value": "',
                                year.toString(),
                                '"}, { "trait_type": "Prediction Month", "value": "',
                                month.toString(),
                                '"}, { "trait_type": "Prediction Day", "value": "',
                                day.toString(),
                                '"}, { "trait_type": "Predicted Team", "value": "',
                                team,
                                '"}]}'
                            )
                        )
                    )
                )
            );
    }
}