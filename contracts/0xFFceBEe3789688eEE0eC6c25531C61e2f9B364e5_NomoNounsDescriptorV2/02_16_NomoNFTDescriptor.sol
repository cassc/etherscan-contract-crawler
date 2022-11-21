// SPDX-License-Identifier: GPL-3.0

/// @title A library used to construct ERC721 token URIs and SVG images

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Base64} from "../nouns-contracts/NounsDescriptorV2/base64-sol/base64.sol";
import {ISVGRenderer} from "../nouns-contracts/NounsDescriptorV2/contracts/interfaces/ISVGRenderer.sol";


library NomoNFTDescriptor {
    using Strings for uint256;
    struct TokenURIParams {
        string name;
        string nounId;
        string description;
        string background;
        ISVGRenderer.Part[] parts;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(ISVGRenderer renderer, TokenURIParams memory params)
    public
    view
    returns (string memory)
    {
        string memory image = generateSVGImage(
            renderer,
            ISVGRenderer.SVGParams({parts : params.parts, background : params.background})
        );

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        string.concat(
                            '{"name":"',
                            params.name,
                            '", "description":"',
                            params.description,
                            '", "image": "',
                            'data:image/svg+xml;base64,',
                            image,
                            '", ',
                            constructAttributes(params.nounId),
                            '}'
                        )
                    )
                )
            )
        );
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructAttributes(string memory nounId)
    internal
    pure
    returns (string memory)
    {
        return string.concat('"attributes": [{"trait_type": "Noun Id","value": "', nounId, '"}]');
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(ISVGRenderer renderer, ISVGRenderer.SVGParams memory params)
    public
    view
    returns (string memory svg)
    {
        return Base64.encode(bytes(renderer.generateSVG(params)));
    }
}