// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "./Base64.sol";

contract AIORBIT is ERC721, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant MAX_TOKENS_PER_WALLET = 3;
    uint256 public constant ROYALTY_FEE_PERCENT = 5;
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    Counters.Counter private _totalTokensMinted;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    struct CommonValues {
        uint256 hue;
        uint256 rotationSpeed;
        uint256 numCircles;
        uint256[] radius;
        uint256[] distance;
        uint256[] strokeWidth;
    }

    function _mint(uint256 _numTokens, address _to) internal {
        require(_totalTokensMinted.current() < MAX_TOKENS, "All tokens have been minted");
        require(balanceOf(_to) + _numTokens <= MAX_TOKENS_PER_WALLET, "Cannot mint more tokens than allowed per wallet");

        for (uint256 i = 0; i < _numTokens; i++) {
            uint256 tokenId = _totalTokensMinted.current() + 1;
            _safeMint(_to, tokenId);
            _totalTokensMinted.increment();
        }
    }

    function mint(uint256 _numTokens) public {
        _mint(_numTokens, msg.sender);
    }

    function royaltyInfo(uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = (_salePrice * ROYALTY_FEE_PERCENT) / 100;
    }

    function generateCommonValues(uint256 _tokenId) internal pure returns (CommonValues memory) {
        uint256 hue = uint256(keccak256(abi.encodePacked(_tokenId, "hue"))) % 360;
        uint256 rotationSpeed = uint256(keccak256(abi.encodePacked(_tokenId, "rotationSpeed"))) % 11 + 5;

        uint256 numCircles = uint256(keccak256(abi.encodePacked(_tokenId, "numCircles"))) % 3 + 3;
        uint256[] memory radius = new uint256[](numCircles);
        uint256[] memory distance = new uint256[](numCircles);
        uint256[] memory strokeWidth = new uint256[](numCircles);

        for (uint256 i = 0; i < numCircles; i++) {
            radius[i] = uint256(keccak256(abi.encodePacked(_tokenId, "radius", i))) % 40 + 20;
            distance[i] = uint256(keccak256(abi.encodePacked(_tokenId, "distance", i))) % 80 + 40;
            strokeWidth[i] = uint256(keccak256(abi.encodePacked(_tokenId, "strokeWidth", i))) % 16 + 5;
        }

        return CommonValues(hue, rotationSpeed, numCircles, radius, distance, strokeWidth);
    }

    function generateSVG(uint256 _tokenId) internal pure returns (string memory) {
        CommonValues memory commonValues = generateCommonValues(_tokenId);

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320">',
                '<rect width="320" height="320" fill="#000"/>',
                '<g transform="translate(0,0)">'
            )
        );

        for (uint256 i = 0; i < commonValues.numCircles; i++) {
            uint256 duration = (commonValues.rotationSpeed > i * 2) ? (commonValues.rotationSpeed - i * 2) : 1;

            uint256 hueStep = 360 / commonValues.numCircles;
            uint256 hue = (uint256(keccak256(abi.encodePacked(_tokenId, "hue"))) + (i * hueStep)) % 360;
            uint256 sat = uint256(keccak256(abi.encodePacked(_tokenId, "sat"))) % 50 + 50;

            string memory strokeColor = string(abi.encodePacked("hsl(", Strings.toString(hue), ",", Strings.toString(sat), "%,54%)"));
            string memory strokeAnimate = string(abi.encodePacked("hsl(", Strings.toString(hue), ",50%,54%);", "hsl(", Strings.toString(hue/2), ",50%,54%);", "hsl(", Strings.toString(hue), ",50%,54%);"));

            uint256 circleX = 160 - commonValues.distance[i] + commonValues.radius[i] + commonValues.strokeWidth[i];
            uint256 circleY = circleX;

            string memory circleXStr = Strings.toString(circleX);
            string memory circleYStr = Strings.toString(circleY);
            string memory radiusStr = Strings.toString(commonValues.radius[i]);
            string memory strokeWidthStr = Strings.toString(commonValues.strokeWidth[i]);
            string memory durationStr = Strings.toString(duration);

            string memory circle = string(
                abi.encodePacked(
                    '<circle cx="', circleXStr, '" cy="', circleYStr, '" r="', radiusStr, '" fill="none" stroke="', strokeColor, '" stroke-width="', strokeWidthStr, '">',
                    '<animateTransform attributeName="transform" type="rotate" from="0 160 160" to="360 160 160" dur="', durationStr, 's" repeatCount="indefinite"/>',
                    '<animate attributeName="stroke" values="', strokeAnimate, '" dur="', durationStr, 's" repeatCount="indefinite"/>',
                    '</circle>'
                )
            );

            svg = string(abi.encodePacked(svg, circle));
        }

        svg = string(abi.encodePacked(svg, '</g>', '</svg>'));

        return svg;
    }

    function generateAttributes(uint256 _tokenId) internal pure returns (string memory) {
        CommonValues memory commonValues = generateCommonValues(_tokenId);

        string memory attributes = string(
            abi.encodePacked(
                '{"trait_type": "distance", "value": "', Strings.toString(commonValues.distance[0]), ' - ', Strings.toString(commonValues.distance[commonValues.distance.length - 1]), ' pixels"},',
                '{"trait_type": "radius", "value": "', Strings.toString(commonValues.radius[0]), ' - ', Strings.toString(commonValues.radius[commonValues.radius.length - 1]), ' pixels"},',
                '{"trait_type": "rotation_speed", "value": "', Strings.toString(commonValues.rotationSpeed), ' seconds"},',
                '{"trait_type": "color", "value": "hsl(', Strings.toString(commonValues.hue), ',50%,54%)"},',
                '{"trait_type": "stroke_width", "value": "', Strings.toString(commonValues.strokeWidth[0]), ' - ', Strings.toString(commonValues.strokeWidth[commonValues.strokeWidth.length - 1]), ' pixels"}'
            )
        );

        return attributes;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");

        // Generate the SVG string
        string memory svg = generateSVG(_tokenId);

        // Get the attribute values
        string memory attributes = generateAttributes(_tokenId);

        // Encode the SVG in base64
        string memory svgBase64 = Base64.encode(bytes(svg));

        // Generate the JSON metadata
        string memory name = string(abi.encodePacked("AIORBIT #", Strings.toString(_tokenId)));
        string memory description = "Orbits generated on-chain by AI with 6,976,080,000 possibilities.";
        string memory imageUri = string(abi.encodePacked("data:image/svg+xml;base64,", svgBase64));
        string memory backgroundColor = "#000000";

        string memory json = string(
            abi.encodePacked(
                '{',
                '"name": "', name, '",',
                '"description": "', description, '",',
                '"image": "', imageUri, '",',
                '"background_color": "', backgroundColor, '",',
                '"attributes": [', attributes, ']',
                '}'
            )
        );

        // Encode the JSON metadata in base64
        string memory jsonBase64 = Base64.encode(bytes(json));

        // Combine the base64-encoded JSON metadata and SVG into the final URI
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function totalSupply() public view returns (uint256) {
        return _totalTokensMinted.current();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_FEES;
    }
}