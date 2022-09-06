// SPDX-License-Identifier: Unlicence
pragma solidity ^0.8.13;

import {Strings} from "./libraries/Strings.sol";
import {IDetail} from "./interfaces/IDetail.sol";
import {DetailHelper} from "./libraries/DetailHelper.sol";

/// @notice Helper to generate SVGs
abstract contract NFTDescriptor {
    IDetail public immutable bodyDetail;
    IDetail public immutable hairDetail;
    IDetail public immutable noseDetail;
    IDetail public immutable eyesDetail;
    IDetail public immutable markDetail;
    IDetail public immutable maskDetail;
    IDetail public immutable mouthDetail;
    IDetail public immutable eyebrowDetail;
    IDetail public immutable earringsDetail;
    IDetail public immutable accessoryDetail;
    IDetail public immutable backgroundDetail;

    constructor(
        IDetail _bodyDetail,
        IDetail _hairDetail,
        IDetail _noseDetail,
        IDetail _eyesDetail,
        IDetail _markDetail,
        IDetail _maskDetail,
        IDetail _mouthDetail,
        IDetail _eyebrowDetail,
        IDetail _earringsDetail,
        IDetail _accessoryDetail,
        IDetail _backgroundDetail
    ) {
        bodyDetail = _bodyDetail;
        hairDetail = _hairDetail;
        noseDetail = _noseDetail;
        eyesDetail = _eyesDetail;
        markDetail = _markDetail;
        maskDetail = _maskDetail;
        mouthDetail = _mouthDetail;
        eyebrowDetail = _eyebrowDetail;
        earringsDetail = _earringsDetail;
        accessoryDetail = _accessoryDetail;
        backgroundDetail = _backgroundDetail;
    }

    struct SVGParams {
        uint8 hair;
        uint8 eye;
        uint8 eyebrow;
        uint8 nose;
        uint8 mouth;
        uint8 mark;
        uint8 earring;
        uint8 accessory;
        uint8 mask;
        uint8 background;
        uint8 skin;
    }

    /// @dev Combine all the SVGs to generate the final image
    function generateSVGImage(SVGParams memory params)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    generateSVGHead(),
                    DetailHelper.getDetailSVG(
                        address(backgroundDetail),
                        params.background
                    ),
                    generateSVGFace(params),
                    DetailHelper.getDetailSVG(
                        address(earringsDetail),
                        params.earring
                    ),
                    DetailHelper.getDetailSVG(address(hairDetail), params.hair),
                    DetailHelper.getDetailSVG(address(maskDetail), params.mask),
                    DetailHelper.getDetailSVG(
                        address(accessoryDetail),
                        params.accessory
                    ),
                    "</svg>"
                )
            );
    }

    /// @dev Combine face items
    function generateSVGFace(SVGParams memory params)
        private
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    DetailHelper.getDetailSVG(address(bodyDetail), params.skin),
                    DetailHelper.getDetailSVG(address(markDetail), params.mark),
                    DetailHelper.getDetailSVG(
                        address(mouthDetail),
                        params.mouth
                    ),
                    DetailHelper.getDetailSVG(address(noseDetail), params.nose),
                    DetailHelper.getDetailSVG(address(eyesDetail), params.eye),
                    DetailHelper.getDetailSVG(
                        address(eyebrowDetail),
                        params.eyebrow
                    )
                )
            );
    }

    /// @dev generate Json Metadata name
    function generateName(SVGParams memory params, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    backgroundDetail.getItemNameById(params.background),
                    " Onii ",
                    Strings.toString(tokenId)
                )
            );
    }

    /// @dev generate Json Metadata description
    function generateDescription(address owner)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "Owned by ",
                    Strings.toHexString(uint256(uint160(owner)))
                )
            );
    }

    /// @dev generate SVG header
    function generateSVGHead() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px"',
                    ' viewBox="0 0 420 420" style="enable-background:new 0 0 420 420;" xml:space="preserve">'
                )
            );
    }

    /// @dev generate Json Metadata attributes
    function generateAttributes(SVGParams memory params)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "[",
                    getJsonAttribute(
                        "Body",
                        bodyDetail.getItemNameById(params.skin),
                        false
                    ),
                    getJsonAttribute(
                        "Hair",
                        hairDetail.getItemNameById(params.hair),
                        false
                    ),
                    getJsonAttribute(
                        "Mouth",
                        mouthDetail.getItemNameById(params.mouth),
                        false
                    ),
                    getJsonAttribute(
                        "Nose",
                        noseDetail.getItemNameById(params.nose),
                        false
                    ),
                    getJsonAttribute(
                        "Eyes",
                        eyesDetail.getItemNameById(params.eye),
                        false
                    ),
                    getJsonAttribute(
                        "Eyebrow",
                        eyebrowDetail.getItemNameById(params.eyebrow),
                        false
                    ),
                    abi.encodePacked(
                        getJsonAttribute(
                            "Mark",
                            markDetail.getItemNameById(params.mark),
                            false
                        ),
                        getJsonAttribute(
                            "Accessory",
                            accessoryDetail.getItemNameById(params.accessory),
                            false
                        ),
                        getJsonAttribute(
                            "Earrings",
                            earringsDetail.getItemNameById(params.earring),
                            false
                        ),
                        getJsonAttribute(
                            "Mask",
                            maskDetail.getItemNameById(params.mask),
                            false
                        ),
                        getJsonAttribute(
                            "Background",
                            backgroundDetail.getItemNameById(params.background),
                            true
                        ),
                        "]"
                    )
                )
            );
    }

    /// @dev Get the json attribute as
    ///    {
    ///      "trait_type": "Skin",
    ///      "value": "Human"
    ///    }
    function getJsonAttribute(
        string memory trait,
        string memory value,
        bool end
    ) private pure returns (string memory json) {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type" : "',
                    trait,
                    '", "value" : "',
                    value,
                    '" }',
                    end ? "" : ","
                )
            );
    }
}