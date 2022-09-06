// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Base64} from "./libraries/Base64.sol";
import {IDetail} from "./interfaces/IDetail.sol";
import {NFTDescriptor} from "./NFTDescriptor.sol";
import {DetailHelper} from "./libraries/DetailHelper.sol";

contract OniiChainDescriptor is NFTDescriptor {
    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Max value for defining probabilities
    uint256 internal constant MAX = 100000;

    bytes32 internal constant SEQ =
        0xc2478f9160e5c21a7c5418d527e74e12cd57cd71dc5f3ee3399b47ca4bb61853;

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    uint256[] internal BACKGROUND_ITEMS = [
        3130,
        2830,
        2600,
        2300,
        2050,
        1825,
        1500,
        0
    ];
    uint256[] internal SKIN_ITEMS = [20000, 10000, 0]; // 80%, 10%, 10%
    uint256[] internal NOSE_ITEMS = [500, 0]; // 99.5%, 0.5%
    uint256[] internal MARK_ITEMS = [
        70000, // 30%
        60000, // 10%
        50000, // 10%
        40000, // 10%
        32000, // 8%
        24000, // 8%
        16000, // 8%
        11000, // 5%
        8000, // 3%
        5000, // 3%
        3000, // 2%
        1000, // 2%
        0 // 1%
    ];
    uint256[] internal EYEBROW_ITEMS = [65000, 40000, 20000, 10000, 4000, 0]; // 35%, 25%, 20%, 10%, 6%, 4%
    uint256[] internal MASK_ITEMS = [
        20000, // 80%
        16000, // 4%
        12000, // 4%
        8000, // 4%
        4000, // 4%
        2000, // 2%
        1000, // 1%
        0 // 1%
    ];
    uint256[] internal EARRINGS_ITEMS = [
        70000, // 30%
        62000, // 8%
        54000, // 8%
        46000, // 8%
        38000, // 8%
        30000, // 8%
        22000, // 8%
        15000, // 7%
        10000, // 5%
        5000, // 5%
        1000, // 4%
        0 // 1%
    ];
    uint256[] internal ACCESSORY_ITEMS = [
        55000, // 45%
        48000, // 7%
        41000, // 7%
        34000, // 7%
        28000, // 6%
        24000, // 4%
        20000, // 4%
        16000, // 4%
        12000, // 4%
        8000, // 4%
        5000, // 3%
        2000, // 3%
        500, // 1.5%
        10, // 0.49%
        0 // 0.01%
    ];
    uint256[] internal MOUTH_ITEMS = [
        92000, // 8%
        84000, // 8%
        76000, // 8%
        68000, // 8%
        60000, // 8%
        52000, // 8%
        44000, // 8%
        36000, // 8%
        28000, // 8%
        20000, // 8%
        12000, // 8%
        6000, // 6%
        2000, // 4%
        0 // 2%
    ];
    uint256[] internal HAIR_ITEMS = [
        97000, // 3%
        94000, // 3%
        91000, // 3%
        88000, // 3%
        85000, // 3%
        82000, // 3%
        79000, // 3%
        76000, // 3%
        73000, // 3%
        70000, // 3%
        67000, // 3%
        64000, // 3%
        61000, // 3%
        58000, // 3%
        55000, // 3%
        52000, // 3%
        49000, // 3%
        46000, // 3%
        43000, // 3%
        40000, // 3%
        37000, // 3%
        34000, // 3%
        31000, // 3%
        28000, // 3%
        25000, // 3%
        22000, // 3%
        19000, // 3%
        16000, // 3%
        13000, // 3%
        10000, // 3%
        3000, // 7%
        1000, // 2%
        0 // 1%
    ];
    uint256[] internal EYE_ITEMS = [
        97000, // 3%
        94000, // 3%
        91000, // 3%
        88000, // 3%
        85000, // 3%
        82000, // 3%
        79000, // 3%
        76000, // 3%
        73000, // 3%
        70000, // 3%
        67000, // 3%
        64000, // 3%
        61000, // 3%
        58000, // 3%
        55000, // 3%
        52000, // 3%
        49000, // 3%
        46000, // 3%
        43000, // 3%
        40000, // 3%
        37000, // 3%
        34000, // 3%
        31000, // 3%
        28000, // 3%
        25000, // 3%
        22000, // 3%
        19000, // 3%
        16000, // 3%
        13000, // 3%
        10000, // 3%
        7000, // 3%
        4000, // 3%
        1000, // 1%
        0 // 1%
    ];

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

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
    )
        NFTDescriptor(
            _bodyDetail,
            _hairDetail,
            _noseDetail,
            _eyesDetail,
            _markDetail,
            _maskDetail,
            _mouthDetail,
            _eyebrowDetail,
            _earringsDetail,
            _accessoryDetail,
            _backgroundDetail
        )
    {}

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Generate full SVG for a given tokenId
    /// @param tokenId The Onii tokenID
    /// @param owner Onii owner address
    /// @return The full SVG (image, name, description,...)
    function tokenURI(uint256 tokenId, address owner)
        external
        view
        returns (string memory)
    {
        // Get SVGParams based on tokenID
        NFTDescriptor.SVGParams memory params = getSVGParams(tokenId);

        // Generate SVG Image
        string memory image = Base64.encode(bytes(generateSVGImage(params)));

        string memory name = NFTDescriptor.generateName(params, tokenId);
        string memory description = NFTDescriptor.generateDescription(owner);
        string memory attributes = NFTDescriptor.generateAttributes(params);

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
                                '", "attributes":',
                                attributes,
                                ', "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getSVG(uint256 tokenId) external view returns (string memory) {
        // Get SVGParams based on tokenID
        NFTDescriptor.SVGParams memory params = getSVGParams(tokenId);

        // Compute background id based on items probabilities
        params.background = getBackgroundId(params);

        return NFTDescriptor.generateSVGImage(params);
    }

    /// @dev Get SVGParams struct from the tokenID
    /// @param tokenId The Onii TokenID
    /// @return The NFTDescription.SVGParams struct
    function getSVGParams(uint256 tokenId)
        public
        view
        returns (NFTDescriptor.SVGParams memory)
    {
        NFTDescriptor.SVGParams memory params = NFTDescriptor.SVGParams({
            hair: generateHairId(
                tokenId,
                uint256(keccak256(abi.encode("onii.hair", SEQ)))
            ),
            eye: generateEyeId(
                tokenId,
                uint256(keccak256(abi.encode("onii.eye", SEQ)))
            ),
            eyebrow: generateEyebrowId(
                tokenId,
                uint256(keccak256(abi.encode("onii.eyebrown", SEQ)))
            ),
            nose: generateNoseId(
                tokenId,
                uint256(keccak256(abi.encode("onii.nose", SEQ)))
            ),
            mouth: generateMouthId(
                tokenId,
                uint256(keccak256(abi.encode("onii.mouth", SEQ)))
            ),
            mark: generateMarkId(
                tokenId,
                uint256(keccak256(abi.encode("onii.mark", SEQ)))
            ),
            earring: generateEarringsId(
                tokenId,
                uint256(keccak256(abi.encode("onii.earrings", SEQ)))
            ),
            accessory: generateAccessoryId(
                tokenId,
                uint256(keccak256(abi.encode("onii.accessory", SEQ)))
            ),
            mask: generateMaskId(
                tokenId,
                uint256(keccak256(abi.encode("onii.mask", SEQ)))
            ),
            skin: generateSkinId(
                tokenId,
                uint256(keccak256(abi.encode("onii.skin", SEQ)))
            ),
            background: 0
        });

        params.background = getBackgroundId(params);

        return params;
    }

    /* -------------------------------------------------------------------------- */
    /*                              PRIVATE FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    function generateHairId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, HAIR_ITEMS, tokenId);
    }

    function generateEyeId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, EYE_ITEMS, tokenId);
    }

    function generateEyebrowId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, EYEBROW_ITEMS, tokenId);
    }

    function generateNoseId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, NOSE_ITEMS, tokenId);
    }

    function generateMouthId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, MOUTH_ITEMS, tokenId);
    }

    function generateMarkId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, MARK_ITEMS, tokenId);
    }

    function generateEarringsId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, EARRINGS_ITEMS, tokenId);
    }

    function generateAccessoryId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, ACCESSORY_ITEMS, tokenId);
    }

    function generateMaskId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, MASK_ITEMS, tokenId);
    }

    function generateSkinId(uint256 tokenId, uint256 seed)
        private
        view
        returns (uint8)
    {
        return DetailHelper.generate(MAX, seed, SKIN_ITEMS, tokenId);
    }

    /// @dev Compute background id based on the params probabilities
    function getBackgroundId(NFTDescriptor.SVGParams memory params)
        private
        view
        returns (uint8)
    {
        if (params.accessory == 15) {
            return 8; // Noface is unreal
        }

        uint256 score = itemScorePosition(params.hair, HAIR_ITEMS) +
            itemScoreProba(params.accessory, ACCESSORY_ITEMS) +
            itemScoreProba(params.earring, EARRINGS_ITEMS) +
            itemScoreProba(params.mask, MASK_ITEMS) +
            itemScorePosition(params.mouth, MOUTH_ITEMS) +
            (itemScoreProba(params.skin, SKIN_ITEMS) / 2) +
            itemScoreProba(params.skin, SKIN_ITEMS) +
            itemScoreProba(params.nose, NOSE_ITEMS) +
            itemScoreProba(params.mark, MARK_ITEMS) +
            itemScorePosition(params.eye, EYE_ITEMS) +
            itemScoreProba(params.eyebrow, EYEBROW_ITEMS);
        return DetailHelper.pickItems(score, BACKGROUND_ITEMS);
    }

    /// @dev Get item score based on his probability
    function itemScoreProba(uint8 item, uint256[] memory ITEMS)
        private
        pure
        returns (uint256)
    {
        uint256 raw = ((item == 1 ? MAX : ITEMS[item - 2]) - ITEMS[item - 1]);
        return ((raw >= 1000) ? raw * 6 : raw) / 1000;
    }

    /// @dev Get item score based on his index
    function itemScorePosition(uint8 item, uint256[] memory ITEMS)
        private
        pure
        returns (uint256)
    {
        uint256 raw = ITEMS[item - 1];
        return ((raw >= 1000) ? raw * 6 : raw) / 1000;
    }
}