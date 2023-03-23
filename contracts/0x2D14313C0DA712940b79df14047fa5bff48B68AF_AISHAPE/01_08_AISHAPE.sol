// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "./Base64.sol";

contract AISHAPE is ERC721A, Ownable {
    uint256 public maxSupply = 10000;
    uint256 public maxFree = 1;
    uint256 public maxPerTx = 10;
    uint256 public price = .003 ether;
    bool public paused = true;

    mapping(address => uint256) private _freeMintCounter;

    constructor() ERC721A("AISHAPE", "SHAPE") {}

    enum ShapeType {
        CIRCLE,
        SQUARE,
        TRIANGLE
    }

    struct CommonValues {
        uint256 hue;
        uint256 rotationSpeed;
        uint256 numShapes;
        uint256[] radius;
        uint256[] distance;
        uint256[] strokeWidth;
        ShapeType[] shapeType;
    }

    function mint(uint256 _numTokens) external payable {
        require(!paused, "Sale paused");

        uint256 _price = (msg.value == 0 &&
            (_freeMintCounter[msg.sender] + _numTokens <= maxFree))
            ? 0
            : price;

        require(_numTokens <= maxPerTx, "Beyond max per transaction");
        require(
            (totalSupply() + _numTokens) <= maxSupply,
            "Beyond max supply"
        );
        require(msg.value >= (_price * _numTokens), "Wrong mint price");

        if (_price == 0) {
            _freeMintCounter[msg.sender] += _numTokens;
        }

        _safeMint(msg.sender, _numTokens);
    }

    function generateCommonValues(uint256 _tokenId)
        internal
        pure
        returns (CommonValues memory)
    {
        uint256 hue = uint256(keccak256(abi.encodePacked(_tokenId, "hue"))) %
            360;
        uint256 rotationSpeed = (uint256(
            keccak256(abi.encodePacked(_tokenId, "rotationSpeed"))
        ) % 11) + 5;

        uint256 numShapes = (uint256(
            keccak256(abi.encodePacked(_tokenId, "numShapes"))
        ) % 3) + 3;
        uint256[] memory radius = new uint256[](numShapes);
        uint256[] memory distance = new uint256[](numShapes);
        uint256[] memory strokeWidth = new uint256[](numShapes);
        ShapeType[] memory shapeType = new ShapeType[](numShapes);

        for (uint256 i = 0; i < numShapes; i++) {
            radius[i] =
                (uint256(keccak256(abi.encodePacked(_tokenId, "radius", i))) %
                    40) +
                20;
            distance[i] =
                (uint256(keccak256(abi.encodePacked(_tokenId, "distance", i))) %
                    80) +
                40;
            strokeWidth[i] =
                (uint256(
                    keccak256(abi.encodePacked(_tokenId, "strokeWidth", i))
                ) % 16) +
                5;
            shapeType[i] = ShapeType(
                uint256(keccak256(abi.encodePacked(_tokenId, "shapeType", i))) %
                    3
            );
        }

        return
            CommonValues(
                hue,
                rotationSpeed,
                numShapes,
                radius,
                distance,
                strokeWidth,
                shapeType
            );
    }

    function _shapeParameters(
        uint256 tokenId,
        CommonValues memory commonValues,
        uint256 i
    )
        internal
        pure
        returns (
            uint256 shapeX,
            uint256 shapeY,
            uint256 strokeWidth,
            string memory strokeColor,
            string memory strokeAnimate,
            uint256 duration
        )
    {
        uint256 distance = commonValues.distance[i];
        uint256 hue = (uint256(keccak256(abi.encodePacked(tokenId, "hue"))) +
            ((i * 360) / commonValues.numShapes)) % 360;
        uint256 sat = (uint256(keccak256(abi.encodePacked(tokenId, "sat"))) %
            50) + 50;

        shapeX = 160 - distance + commonValues.radius[i];
        shapeY = shapeX;
        strokeWidth = commonValues.strokeWidth[i];
        strokeColor = string(
            abi.encodePacked(
                "hsl(",
                Strings.toString(hue),
                ",",
                Strings.toString(sat),
                "%,54%)"
            )
        );
        strokeAnimate = string(
            abi.encodePacked(
                "hsl(",
                Strings.toString(hue),
                ",50%,54%);",
                "hsl(",
                Strings.toString(hue / 2),
                ",50%,54%);",
                "hsl(",
                Strings.toString(hue),
                ",50%,54%);"
            )
        );
        duration = (commonValues.rotationSpeed > i * 2)
            ? (commonValues.rotationSpeed - i * 2)
            : 1;
    }

    function _generateCircle(
        CommonValues memory commonValues,
        uint256 i,
        uint256 shapeX,
        uint256 shapeY,
        uint256 strokeWidth,
        string memory strokeColor,
        string memory strokeAnimate,
        uint256 duration
    ) internal pure returns (string memory) {
        string memory radiusStr = Strings.toString(commonValues.radius[i]);
        string memory durationStr = Strings.toString(duration);

        return
            string(
                abi.encodePacked(
                    '<circle cx="',
                    Strings.toString(shapeX),
                    '" cy="',
                    Strings.toString(shapeY),
                    '" r="',
                    radiusStr,
                    '" fill="none" stroke="',
                    strokeColor,
                    '" stroke-width="',
                    Strings.toString(strokeWidth),
                    '">',
                    '<animateTransform attributeName="transform" type="rotate" from="0 160 160" to="360 160 160" dur="',
                    durationStr,
                    's" repeatCount="indefinite"/>',
                    '<animate attributeName="stroke" values="',
                    strokeAnimate,
                    '" dur="',
                    durationStr,
                    's" repeatCount="indefinite"/>',
                    "</circle>"
                )
            );
    }

    function _generateSquare(
        CommonValues memory commonValues,
        uint256 i,
        uint256 shapeX,
        uint256 shapeY,
        uint256 strokeWidth,
        string memory strokeColor,
        string memory strokeAnimate,
        uint256 duration
    ) internal pure returns (string memory) {
        uint256 sideLength = commonValues.radius[i] * 2;
        string memory durationStr = Strings.toString(duration);

        return
            string(
                abi.encodePacked(
                    '<rect x="',
                    Strings.toString(shapeX),
                    '" y="',
                    Strings.toString(shapeY),
                    '" width="',
                    Strings.toString(sideLength),
                    '" height="',
                    Strings.toString(sideLength),
                    '" fill="none" stroke="',
                    strokeColor,
                    '" stroke-width="',
                    Strings.toString(strokeWidth),
                    '">',
                    '<animateTransform attributeName="transform" type="rotate" from="0 160 160" to="360 160 160" dur="',
                    durationStr,
                    's" repeatCount="indefinite"/>',
                    '<animate attributeName="stroke" values="',
                    strokeAnimate,
                    '" dur="',
                    durationStr,
                    's" repeatCount="indefinite"/>',
                    "</rect>"
                )
            );
    }

    function _generateTriangle(
        CommonValues memory commonValues,
        uint256 i,
        uint256 shapeX,
        uint256 shapeY,
        uint256 strokeWidth,
        string memory strokeColor,
        string memory strokeAnimate,
        uint256 duration
    ) internal pure returns (string memory) {
        uint256 sideLength = commonValues.radius[i] * 2;
        string memory points = string(
            abi.encodePacked(
                Strings.toString(shapeX - sideLength / 2),
                " ",
                Strings.toString(shapeY + sideLength / 2),
                ",",
                Strings.toString(shapeX + sideLength / 2),
                " ",
                Strings.toString(shapeY + sideLength / 2),
                ",",
                Strings.toString(shapeX),
                " ",
                Strings.toString(shapeY - sideLength / 2)
            )
        );
        string memory durationStr = Strings.toString(duration);

        return
            string(
                abi.encodePacked(
                    '<polygon points="',
                    points,
                    '" fill="none" stroke="',
                    strokeColor,
                    '" stroke-width="',
                    Strings.toString(strokeWidth),
                    '">',
                    '<animateTransform attributeName="transform" type="rotate" from="0 160 160" to="360 160 160" dur="',
                    durationStr,
                    's" repeatCount="indefinite"/>',
                    '<animate attributeName="stroke" values="',
                    strokeAnimate,
                    '" dur="',
                    durationStr,
                    's" repeatCount="indefinite"/>',
                    "</polygon>"
                )
            );
    }

    function generateSVG(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        CommonValues memory commonValues = generateCommonValues(tokenId);

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320">',
                '<rect width="320" height="320" fill="#000"/>',
                '<g transform="translate(0,0)">'
            )
        );

        for (uint256 i = 0; i < commonValues.numShapes; i++) {
            string memory shape;

            (
                uint256 shapeX,
                uint256 shapeY,
                uint256 strokeWidth,
                string memory strokeColor,
                string memory strokeAnimate,
                uint256 duration
            ) = _shapeParameters(tokenId, commonValues, i);

            if (commonValues.shapeType[i] == ShapeType.CIRCLE) {
                shape = _generateCircle(
                    commonValues,
                    i,
                    shapeX,
                    shapeY,
                    strokeWidth,
                    strokeColor,
                    strokeAnimate,
                    duration
                );
            } else if (commonValues.shapeType[i] == ShapeType.SQUARE) {
                shape = _generateSquare(
                    commonValues,
                    i,
                    shapeX,
                    shapeY,
                    strokeWidth,
                    strokeColor,
                    strokeAnimate,
                    duration
                );
            } else {
                shape = _generateTriangle(
                    commonValues,
                    i,
                    shapeX,
                    shapeY,
                    strokeWidth,
                    strokeColor,
                    strokeAnimate,
                    duration
                );
            }

            svg = string(abi.encodePacked(svg, shape));
        }

        svg = string(abi.encodePacked(svg, "</g></svg>"));
        return svg;
    }

    function _getShapeTypeAsString(ShapeType shapeType)
        private
        pure
        returns (string memory)
    {
        if (shapeType == ShapeType.CIRCLE) {
            return "Circle";
        } else if (shapeType == ShapeType.SQUARE) {
            return "Square";
        } else if (shapeType == ShapeType.TRIANGLE) {
            return "Triangle";
        } else {
            return "Unknown";
        }
    }

    function generateAttributes(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        CommonValues memory commonValues = generateCommonValues(tokenId);
        string memory attributes = "";

        for (uint256 i = 0; i < commonValues.numShapes; i++) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type":"Shape ", "value":"',
                    _getShapeTypeAsString(commonValues.shapeType[i]),
                    '"},'
                )
            );
        }

        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"Number of Shapes", "value":',
                Strings.toString(commonValues.numShapes),
                "},",
                '{"trait_type":"Distance", "value":',
                Strings.toString(commonValues.distance[0]),
                "},",
                '{"trait_type":"Radius", "value":',
                Strings.toString(commonValues.radius[0]),
                "},",
                '{"trait_type":"Rotation Speed", "value":',
                Strings.toString(commonValues.rotationSpeed),
                "},",
                '{"trait_type":"Stroke Width", "value":',
                Strings.toString(commonValues.strokeWidth[0]),
                "}"
            )
        );

        return attributes;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory svg = generateSVG(tokenId);
        string memory attributes = generateAttributes(tokenId);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "AISHAPE #',
                        Strings.toString(tokenId),
                        '", "description": "The shapes are all animated on-chain, created by AI with 6,976,080,000 different possibilities. Each animated shape has its own exclusive rank.", "attributes":[',
                        attributes,
                        '], "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setPaused() external onlyOwner {
        paused = !paused;
    }

    function decreaseSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply < maxSupply, "Beyond max supply");
        maxSupply = _maxSupply;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxFreeMint(uint256 _maxFree) external onlyOwner {
        maxFree = _maxFree;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function airdrop(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount < maxSupply, "Beyond max supply");
        _mint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}