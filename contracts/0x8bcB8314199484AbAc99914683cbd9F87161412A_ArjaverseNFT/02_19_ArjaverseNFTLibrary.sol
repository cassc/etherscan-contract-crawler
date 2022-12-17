// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
import "./Base64.sol";

library ArjaverseNFTLibrary {

    struct Metadata {
        uint16 score;
        uint8 background;
        uint8 effect;
        uint8 body;
        uint8 decoration;
        uint8 eyes;
        uint8 ball;
        bool isRevealed;
    }

    string constant BACKGROUND = "Background";
    string constant SPECIAL_EFFECT = "SpecialEffect";
    string constant BODY = "Body";
    string constant DECORATION = "Decoration";
    string constant EYES = "Eyes";
    string constant BALL = "Ball";

    function concatHref(
        string memory _baseURI,
        string memory _trait,
        string memory _traitArr
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(_baseURI, _trait, "/", _traitArr, ".png"));
    }

    function buildImagePart1() internal pure returns (string memory) {
        return
            string(abi.encodePacked(
                '<svg width="800" height="800" xmlns="http://www.w3.org/2000/svg">',
                '<rect height="800" width="800" y="0" x="0" />'
            ));
    }
    function buildImagePart2(
        string memory background,
        string memory effect,
        string memory body
    ) internal pure returns (string memory) {
        return 
            string(abi.encodePacked(
                '<image href="',
                background,
                '" height="800" width="800" />',
                '<image href="',
                effect,
                '" height="800" width="800" />',
                '<image href="',
                body,
                '" height="800" width="800" />'
            ));
    }

    function buildImagePart3(
        string memory decoration,
        string memory eyes,
        string memory ball
    ) internal pure returns (string memory) {
        return 
            string(abi.encodePacked(
                '<image href="',
                decoration,
                '" height="800" width="800" />',
                '<image href="',
                eyes,
                '" height="800" width="800" />',
                '<image href="',
                ball,
                '" height="800" width="800" />',
                '</svg>'
            ));
    }

    function getAttributesLeft(
        string memory background,
        string memory effect,
        string memory body
    ) internal pure returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type": "Background","value":"',
                    background,
                    '"}',
                    ',{"trait_type": "Effect","value":"',
                    effect,
                    '"}',
                    ',{"trait_type": "Body","value":"',
                    body,
                    '"}'
                )
            );
    }

    function getAttributesRight(
        string memory decoration,
        string memory eyes,
        string memory ball
    ) internal pure returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    ',{"trait_type": "Decoration","value":"',
                    decoration,
                    '"}',
                    ',{"trait_type": "Eyes","value":"',
                    eyes,
                    '"}',
                    ',{"trait_type": "Ball","value":"',
                    ball,
                    '"}'
                )
            );
    }
}