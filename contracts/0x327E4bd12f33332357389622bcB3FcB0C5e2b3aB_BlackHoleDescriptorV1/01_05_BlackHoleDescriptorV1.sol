// SPDX-License-Identifier: MIT

/*********************************
*                                *
*               •                *
*                                *
 *********************************/

pragma solidity ^0.8.13;

import './lib/base64.sol';
import "./IBlackHoleDescriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlackHoleDescriptorV1 is IBlackHoleDescriptor {
    struct Category {
        string color;
        string name;
    }
    using Strings for uint256;
    string private constant SVG_END_TAG = '</svg>';

    function tokenURI(uint256 tokenId, string memory name, uint256 mergers) external pure override returns (string memory) {
        name = bytes(name).length == 0 ? '' : name;

        uint256 radius = getRadius(mergers);
        uint256 solarMass = getSolarMass(mergers);
        Category memory category = getCategory(solarMass);

        string memory solarMassText = solarMass.toString();

        if (solarMass > 9999) {
            solarMassText = string.concat((solarMass / 1000).toString(), 'x10\xC2\xB3');
        }
        if (solarMass > 99999) {
            solarMassText = string.concat((solarMass / 10000).toString(), 'x10\xE2\x81\xB4');
        }

        string memory rawSvg = string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="100%" height="100%" fill="#ddd"/>',
                '<circle cx="160" cy="160" r="', radius.toString(), '" fill="', category.color,'"/>',
                '<text x="10" y="310" text-anchor="start" fill="#333" font-size="12" font-family="Courier,Arial">', name, '</text>',
                '<text x="310" y="310" text-anchor="end" fill="#333" font-size="12" font-family="Courier,Arial">', mergers.toString(), ' MRG | ', solarMassText, ' M<tspan dy="3" dx="1">\xE2\x98\x89</tspan></text>',
                SVG_END_TAG
            )
        );

        string memory encodedSvg = Base64.encode(bytes(rawSvg));
        string memory description = 'BLVCK HOLES. Collect them. Name them. Merge them. The biggest one wins.';

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"name":"BLVCK HOLES #', tokenId.toString(), '",',
                            '"description":"', description, '",',
                            '"image": "', 'data:image/svg+xml;base64,', encodedSvg, '",',
                            '"attributes": [{"trait_type": "Name", "value": "', name, '"},',
                                '{"trait_type": "Mergers", "value": ', mergers.toString(),'},',
                                '{"trait_type": "Solar mass", "value": ', solarMass.toString(),'},',
                                '{"trait_type": "Category", "value": "',category.name,'"}',
                                ']',
                            '}')
                    )
                )
            )
        );
    }

    function getRadius(uint256 mergers) public pure returns (uint256) {
        uint256 radius = 120;

        if (mergers < 10) {
            radius += mergers * 10;
        } else if (mergers <= 420) {
            radius += 100;
            radius += (mergers - 10) * 2;
        } else {
            radius += 920;
            radius += (mergers - 420) / 10;
        }

        return radius / 10;
    }

    function getSolarMass(uint256 mergers) public pure returns (uint256) {
        uint256 solarMass = 1;

        if (mergers < 21) {
            solarMass += mergers / 2;
        } else if (mergers < 61) {
            solarMass += 10;
            solarMass += (mergers - 20);
        } else {
            solarMass += 50;
            solarMass += (mergers - 60) * (mergers - 60);
        }

        return solarMass;
    }

    function getCategory(uint256 solarMass) public pure returns (Category memory) {
        if (solarMass < 6) {
            return Category('#20262E', 'Miniature');
        }

        if (solarMass < 51) {
            return Category('#20262E', 'Stellar-mass');
        }

        if (solarMass < 50001) {
            return Category('#20262E', 'Intermediate-mass');
        }

        return Category('#20262E', 'Supermassive');
    }
}