// SPDX-License-Identifier: MIT

/**
 *
 * Created by Satoshi Nakajima (@snakajima)
 * update for Noun 556 by eiba8884
 */

pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./NounsAssetProviderV2.sol";
import "randomizer.sol/Randomizer.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../packages/graphics/Path.sol";
import "../packages/graphics/SVG.sol";
import "../packages/graphics/Text.sol";

contract JapaNounsProvider2 is IAssetProviderEx, Ownable, IERC165 {
    using Strings for uint256;
    using Randomizer for Randomizer.Seed;
    using Vector for Vector.Struct;
    using Path for uint256[];
    using SVG for SVG.Element;
    using TX for string;
    using Trigonometry for uint256;

    NounsAssetProviderV2 public immutable nounsProvider;
    uint256[] public nounsId;

    struct pathElement {
        bytes d;
        string color;
    }

    constructor(
        NounsAssetProviderV2 _nounsProvider,
        uint256[] memory _nounsId
    ) {
        nounsProvider = _nounsProvider;
        nounsId = _nounsId;
    }

    function setNounsId(uint256[] memory _nounsId) external onlyOwner {
        nounsId = _nounsId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAssetProvider).interfaceId ||
            interfaceId == type(IAssetProviderEx).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function getProviderInfo()
        external
        view
        override
        returns (ProviderInfo memory)
    {
        return ProviderInfo("japaNouns", "japaNouns", this);
    }

    function totalSupply() external pure override returns (uint256) {
        return 0;
    }

    function processPayout(uint256 _assetId) external payable override {
        address payable payableTo = payable(owner());
        payableTo.transfer(msg.value);
        emit Payout("japaNouns", _assetId, payableTo, msg.value);
    }

    function generateTraits(uint256 _assetId)
        external
        pure
        override
        returns (string memory traits)
    {
        // nothing to return
    }

    // Hack to deal with too many stack variables
    struct Stackframe {
        uint256 color;
        uint256 y;
    }

    function background(uint256 _assetId)
        internal
        pure
        returns (SVG.Element memory)
    {
        Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);

        // // determine num of elements and each height
        uint256 numOfElements = 0;
        uint256 totalY = 0;
        uint256[] memory heights = new uint256[](10); // elements max num

        while (numOfElements < heights.length) {
            uint256 height;
            (seed, height) = seed.random(256);
            if (height < 100) {
                height += 100;
            }

            if (
                numOfElements == heights.length - 1 || totalY + height >= 1024
            ) {
                heights[numOfElements] = 1024 - totalY;
                break;
            } else {
                heights[numOfElements] = height;
            }
            totalY += height;
            numOfElements++;
        }
        numOfElements++;

        // string[5] memory colors = ['#324e76', '#753a36', '#4f5d2d', '#543c72', '#474747'];
        string[5] memory colors = [
            "#30507c",
            "#7b3935",
            "#53622c",
            "#573b78",
            "#494949"
        ];
        SVG.Element[] memory elements = new SVG.Element[](numOfElements);

        totalY = 0;
        for (uint256 i = 0; i < numOfElements; i++) {
            Stackframe memory stack;
            (seed, stack.color) = seed.random(colors.length);
            stack.y = totalY;
            totalY += heights[i];

            SVG.Element memory ele = SVG
                .rect(0, int256(stack.y), 1024, heights[i])
                .fill(colors[stack.color]);
            elements[i] = ele;
        }

        return SVG.group(elements);
    }

    struct StackFrame2 {
        uint256 nounsId;
        string idNouns;
        SVG.Element svgNouns;
        string svg;
        SVG.Element nouns;
    }

    function hands() public pure returns (SVG.Element memory) {
        bytes
            memory hand = "M1 0h1v2h1V1h1V0h1v1H4v1h2V1h1v1H6v1H5v1h2v1H6v1H5V5H3v1H0V2h1z";
        return
            SVG.list(
                [
                    SVG
                        .path(hand)
                        .fill("#f9f5cb")
                        .transform("scale(26.99) translate(10.93 31.9)")
                        .id("hand"),
                    SVG.use("hand").transform("translate(353 0)")
                ]
            );
    }

    struct RGB {
        uint256 r;
        uint256 g;
        uint256 b;
    }

    function accesories(uint256 _assetId)
        public
        pure
        returns (SVG.Element memory)
    {
        Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);
        bytes
            memory bird = "M4 0h1v2h1v1H5v2H2v1H1V5h1V4H1V3H0V2h3V1h1zm1 2H4v1h1z";
        // string[4] memory colors = ['pink', 'orange', 'yellow', 'white'];
        // uint256 color;
        // (seed, color) = seed.random(colors.length);
        RGB memory rgb;
        (seed, rgb.r) = seed.random(156);
        (seed, rgb.g) = seed.random(156);
        (seed, rgb.b) = seed.random(156);
        string memory color = string(abi.encodePacked(
            "rgb(",
            (rgb.r + 100).toString(),
            ",",
            (rgb.g + 100).toString(),
            ",",
            (rgb.b + 100).toString(),
            ")"
        ));

        string[5] memory distances = ["2", "8.5", "16", "23.5", "30"];
        string memory transform = string(
            abi.encodePacked(
                "scale(26.99) translate(",
                distances[_assetId % 5],
                " 1)"
            )
        );
        // SVG.Element memory birdEle = SVG.path(bird).fill(colors[color]).transform(transform).id('bird');
        SVG.Element memory birdEle = SVG
            .path(bird)
            .fill(color)
            .transform(transform)
            .id("bird");

        // imageType:0 => UFO, 1=>Plane other=>NothingÇ
        uint256 imageType;
        (seed, imageType) = seed.random(20); // percentage

        if ((_assetId % 5) != 4 || imageType > 1) {
            // if (false) {
            return birdEle;
        } else if (imageType == 0) {
            //return bird and ufo
            SVG.Element memory ufo = SVG
                .group(
                    SVG.list(
                        [
                            SVG.path("M1 0h2v1H1zm0 3h1v1H1zm2 0h1v1H3z").fill(
                                "#fb4694"
                            ),
                            SVG.path("M0 1h2v1h1V1h1v2H0z").fill("#2a83f6"),
                            SVG.path("M2 1h1v1H2z").fill("#caeff9"),
                            SVG.path("M0 3h1v1H0zm2 0h1v1H2z").fill("#ffe939")
                        ]
                    )
                )
                .transform("scale(26.99) translate(2 2)")
                .id("ufo");
            return SVG.list([birdEle, ufo]);
        } else {
            //return bird and plane
            SVG.Element memory plane = SVG
                .group(
                    SVG.list(
                        [
                            SVG.path("M0 0h1v1H0zm2 0h2v1h1v1H3V1H2z").fill(
                                "#9cb4b8"
                            ),
                            SVG.path("M1 1h2v1H1z").fill("#f3322c"),
                            SVG.path("M5 1h1v1H5zM2 2h1v1H2z").fill("#fff")
                        ]
                    )
                )
                .transform("scale(26.99) translate(2 2)")
                .id("plane");
            return SVG.list([birdEle, plane]);
        }
    }

    function generateSVGPart(uint256 _assetId)
        public
        view
        override
        returns (string memory svgPart, string memory tag)
    {
        Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);
        StackFrame2 memory stack;
        tag = string(abi.encodePacked("japaNouns", _assetId.toString()));

        (seed, stack.nounsId) = seed.random(nounsId.length);
        (stack.svg, stack.idNouns) = nounsProvider.getNounsSVGPart(
            nounsId[stack.nounsId]
        );
        stack.svgNouns = SVG.element(bytes(stack.svg));
        stack.nouns = SVG.group(
            [
                background(_assetId),
                accesories(_assetId),
                SVG.use(stack.idNouns).transform(
                    "scale(0.85) translate(90 180)"
                ),
                hands()
            ]
        );

        svgPart = string(SVG.list([stack.svgNouns, stack.nouns.id(tag)]).svg());
    }

    function generateSVGDocument(uint256 _assetId)
        external
        view
        override
        returns (string memory document)
    {
        string memory svgPart;
        string memory tag;
        (svgPart, tag) = generateSVGPart(_assetId);
        document = SVG.document(
            "0 0 1024 1024",
            bytes(svgPart),
            SVG.use(tag).svg()
        );
    }
}