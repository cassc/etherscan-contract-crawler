//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";

import "./ChecksArt.sol";
import "../interfaces/IChecks.sol";
import "./Utilities.sol";

/**

✓✓✓✓✓✓✓  ✓✓✓✓✓✓✓✓    ✓✓✓✓✓✓    ✓✓✓✓✓✓✓✓   ✓✓✓✓✓✓✓     ✓✓
✓✓       ✓✓     ✓✓  ✓✓    ✓✓   ✓✓    ✓✓  ✓✓     ✓✓  ✓✓✓✓
✓✓       ✓✓     ✓✓  ✓✓             ✓✓           ✓✓    ✓✓
✓✓✓✓✓✓   ✓✓✓✓✓✓✓✓   ✓✓            ✓✓      ✓✓✓✓✓✓✓     ✓✓
✓✓       ✓✓   ✓✓    ✓✓           ✓✓      ✓✓           ✓✓
✓✓       ✓✓    ✓✓   ✓✓    ✓✓     ✓✓      ✓✓           ✓✓
✓✓✓✓✓✓✓  ✓✓     ✓✓   ✓✓✓✓✓✓      ✓✓      ✓✓✓✓✓✓✓✓✓   ✓✓✓✓

@title  ChecksMetadata
@author VisualizeValue
@notice Renders ERC721 compatible metadata for Checks.
*/
library ChecksMetadata {

    /// @dev Render the JSON Metadata for a given Checks token.
    /// @param tokenId The id of the token to render.
    /// @param checks The DB containing all checks.
    function tokenURI(
        uint256 tokenId, IChecks.Checks storage checks
    ) public view returns (string memory) {
        IChecks.Check memory check = ChecksArt.getCheck(tokenId, checks);

        bytes memory svg = ChecksArt.generateSVG(check, checks);

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Checks ', Utilities.uint2str(tokenId), '",',
                '"description": "This artwork may or may not be notable.",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(svg),
                    '",',
                '"animation_url": ',
                    '"data:text/html;base64,',
                    Base64.encode(generateHTML(tokenId, svg)),
                    '",',
                '"attributes": [', attributes(check), ']',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

    /// @dev Render the JSON atributes for a given Checks token.
    /// @param check The check to render.
    function attributes(IChecks.Check memory check) public pure returns (bytes memory) {
        bool showVisualAttributes = check.isRevealed && check.hasManyChecks;
        bool showAnimationAttributes = check.isRevealed && check.checksCount > 0;

        return abi.encodePacked(
            showVisualAttributes
                ? trait('Color Band', colorBand(ChecksArt.colorBandIndex(check, check.stored.divisorIndex)), ',')
                : '',
            showVisualAttributes
                ? trait('Gradient', gradients(ChecksArt.gradientIndex(check, check.stored.divisorIndex)), ',')
                : '',
            showAnimationAttributes
                ? trait('Speed', check.speed == 4 ? '2x' : check.speed == 2 ? '1x' : '0.5x', ',')
                : '',
            showAnimationAttributes
                ? trait('Shift', check.direction == 0 ? 'IR' : 'UV', ',')
                : '',
            check.isRevealed == false
                ? trait('Revealed', 'No', ',')
                : '',
            trait('Checks', Utilities.uint2str(check.checksCount), ','),
            trait('Day', Utilities.uint2str(check.stored.day), '')
        );
    }

    /// @dev Get the names for different gradients. Compare ChecksArt.GRADIENTS.
    /// @param gradientIndex The index of the gradient.
    function gradients(uint8 gradientIndex) public pure returns (string memory) {
        return [
            'None', 'Linear', 'Double Linear', 'Reflected', 'Double Angled', 'Angled', 'Linear Z'
        ][gradientIndex];
    }

    /// @dev Get the percentage values for different color bands. Compare ChecksArt.COLOR_BANDS.
    /// @param bandIndex The index of the color band.
    function colorBand(uint8 bandIndex) public pure returns (string memory) {
        return [
            'Eighty', 'Sixty', 'Forty', 'Twenty', 'Ten', 'Five', 'One'
        ][bandIndex];
    }

    /// @dev Generate the SVG snipped for a single attribute.
    /// @param traitType The `trait_type` for this trait.
    /// @param traitValue The `value` for this trait.
    /// @param append Helper to append a comma.
    function trait(
        string memory traitType, string memory traitValue, string memory append
    ) public pure returns (string memory) {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }

    /// @dev Generate the HTML for the animation_url in the metadata.
    /// @param tokenId The id of the token to generate the embed for.
    /// @param svg The rendered SVG code to embed in the HTML.
    function generateHTML(uint256 tokenId, bytes memory svg) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<!DOCTYPE html>',
            '<html lang="en">',
            '<head>',
                '<meta charset="UTF-8">',
                '<meta http-equiv="X-UA-Compatible" content="IE=edge">',
                '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
                '<title>Check #', Utilities.uint2str(tokenId), '</title>',
                '<style>',
                    'html,',
                    'body {',
                        'margin: 0;',
                        'background: #EFEFEF;',
                        'overflow: hidden;',
                    '}',
                    'svg {',
                        'max-width: 100vw;',
                        'max-height: 100vh;',
                    '}',
                '</style>',
            '</head>',
            '<body>',
                svg,
            '</body>',
            '</html>'
        );
    }

}