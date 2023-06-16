// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Metadata} from "./Metadata.sol";
import {Util} from "./Util.sol";
import {Traits} from "./Traits.sol";
import {Background} from "./Background.sol";
import {TextBody} from "./TextBody.sol";
import {TextLine} from "./TextLine.sol";
import {TextEdition} from "./TextEdition.sol";
import {TextOf} from "./TextOf.sol";
import {Traits} from "./Traits.sol";
import {SVG} from "./SVG.sol";
import {ConceptStruct} from "./ConceptStruct.sol";

/// @notice Adopted from Bibos (0xf528e3381372c43f5e8a55b3e6c252e32f1a26e4)
library Render {
    string public constant description =
        "The BEEF series.";

    /*//////////////////////////////////////////////////////////////
                                TOKENURI
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 _tokenId, ConceptStruct.Concept memory concept, string memory base64font) internal pure returns (string memory) {
        bytes memory descriptionConcat;
        for (uint i = 0; i < concept._bodyText.length; i++) {
            descriptionConcat = abi.encodePacked(descriptionConcat, Util.bytes32ToBytes(concept._bodyText[i]));
        }
        return
            Metadata.encodeMetadata({
                _tokenId: _tokenId,
                _name: Util.bytes32ToString(concept._title),
                _description: string(abi.encodePacked(descriptionConcat)),
                _svg: _svg(_tokenId, concept, base64font)
            });
    }

    function renderSVG(uint256 _tokenId, ConceptStruct.Concept memory concept, string memory base64font) internal pure returns (string memory) {
        return _svg(_tokenId, concept, base64font);
    }

    function renderSVGBase64(uint256 _tokenId, ConceptStruct.Concept memory concept, string memory base64font) internal pure returns (string memory) {
        return Metadata._encodeSVG(_svg(_tokenId, concept, base64font));
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _svg(
        uint256 _tokenId,
        ConceptStruct.Concept memory _concept,
        string memory base64font
    ) internal pure returns (string memory) {
        bool isBeef = _tokenId == 4 || _tokenId == 8 || _tokenId == 12 || _tokenId == 23 || _tokenId == 32 || _tokenId == 35 || _tokenId == 36 || _tokenId == 37;
        return
            SVG.element(
                "svg",
                SVG.svgAttributes(),
                string.concat(
                    '<defs><style>',
                    '@font-face {font-family: "Norw";src: url("',
                        base64font,
                    '");}',
                    'text {text-transform: uppercase;'
                    '}</style></defs>'
                ),
                Background.render(isBeef),
                _renderText(_tokenId, _concept)
            );
    }

    function _renderText(uint256 _tokenId, ConceptStruct.Concept memory _concept) internal pure returns (string memory) {
        // uint256 titleOffset = 155;
        // uint256 bodyOffset = 155 + 60;
        uint256 smallPrintOffset = 215 + _concept._bodyText.length * 30 + (_concept._bodyText.length > 0 ? 50 : 0);
        uint256 statusOffset = smallPrintOffset + _concept._smallPrintText.length * 20 + (_concept._smallPrintText.length > 0 ? 50 : 0);
        return SVG.element(
            "g",
            "",
            TextLine.render(_concept._title, 155, false),
            TextBody.render(_concept._bodyText, 215, false),
            TextBody.render(_concept._statusText, statusOffset, false),
            TextBody.render(_concept._smallPrintText, smallPrintOffset, true),
            TextEdition.render(bytes32(abi.encodePacked(Util.uint256ToString(_tokenId)))),
            TextOf.render(_editionTextConcat(_tokenId, _concept))
        );
    }

    function _editionTextConcat(uint256 _tokenId, ConceptStruct.Concept memory _concept) internal pure returns (bytes32) {
        uint256 editionCount = _tokenId - _concept._editionTokenRangeStart + 1;
        return bytes32(abi.encodePacked(Util.uint256ToString(editionCount), " of ", Util.uint256ToString(_concept._editionSize)));
    }

    function _name(uint256 _tokenId) internal pure returns (string memory) {
        return string.concat("Beef ", Util.uint256ToString(_tokenId, 4));
    }
}