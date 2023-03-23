// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

contract PixelWhimsy is ERC721 {
    using Strings for uint256;
    using Base64 for bytes;

    uint256 public constant PIXEL_DIMENSION = 10;
    uint256 public constant MAX_SUPPLY = 420;
    mapping(uint256 => ArtData) private _art;
    struct ArtData {
        uint256 packedArt;
        string color;
    }
    address public governance;
    uint256 public currentTokenId;
    uint256 public totalSupply;

    constructor(address _governance) ERC721("PixelWhimsy", "PXLWMS") {
        governance = _governance;
        currentTokenId = 1;
        totalSupply = 0;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance can call this function");
        _;
    }

    function _initializeArt(uint256[] memory tokenIds, string[] memory artData, string[] memory colors) private {
        require(tokenIds.length == artData.length, "Mismatch in tokenIds and artData lengths");
        require(tokenIds.length == colors.length, "Mismatch in tokenIds and colors lengths");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            bytes memory art = bytes(artData[i]);
            require(art.length == (PIXEL_DIMENSION * PIXEL_DIMENSION), "Invalid art length");
            ArtData memory newArtData = ArtData(_toPacked(art), colors[i]);
            _art[tokenId] = newArtData;
        }
    }

    function mintNFT(string calldata artData, string calldata color) external payable {
        require(currentTokenId <= MAX_SUPPLY, "Max supply reached");
        require(msg.value >= 0.0069 ether, "Insufficient payment, mint price is 0.0069 ETH");
        bytes memory art = bytes(artData);
        require(art.length == (PIXEL_DIMENSION * PIXEL_DIMENSION), "Invalid art length");
        _art[currentTokenId] = ArtData(_toPacked(art), color);
        _safeMint(msg.sender, currentTokenId);
        currentTokenId += 1;

        (bool success, ) = governance.call{value: msg.value}("");
        require(success, "Failed to send Ether to governance");
        totalSupply++;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        bytes memory art = _fromPacked(_art[tokenId].packedArt);
        string memory svg = generateSVG(art, _art[tokenId].color);
        string memory json = string(abi.encodePacked('{"name": "PixelWhimsy #', tokenId.toString(), '", "description": "An on-chain 10x10 pixel art NFT.", "image": "data:image/svg+xml;base64,', bytes(svg).encode(), '"}'));
        return string(abi.encodePacked("data:application/json;base64,", bytes(json).encode()));
    }

    function generateSVG(bytes memory art, string memory color) private pure returns (string memory) {
        string memory svgPrefix = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">';
        string memory svgSuffix = "</svg>";
        string memory svgContent;

        svgContent = string(abi.encodePacked('<path fill="', color, '" d="'));
        for (uint256 i = 0; i < PIXEL_DIMENSION; i++) {
            for (uint256 j = 0; j < PIXEL_DIMENSION; j++) {
                if (art[i * PIXEL_DIMENSION + j] == bytes1('1')) {
                    svgContent = string(abi.encodePacked(svgContent, 'M', j.toString(), ',', i.toString(), 'h1v1h-1z'));
                }
            }
        }
        svgContent = string(abi.encodePacked(svgContent, '" />'));

        return string(abi.encodePacked(svgPrefix, svgContent, svgSuffix));
    }

    function _toPacked(bytes memory art) private pure returns (uint256) {
        require(art.length == 100, "Invalid art length");
        uint256 result = 0;
        for (uint256 i = 0; i < 100; i++) {
            if (art[i] == bytes1('1')) {
                result |= (1 << i);
            }
        }
        return result;
    }

    function _fromPacked(uint256 packedArt) private pure returns (bytes memory) {
        bytes memory result = new bytes(100);
        for (uint256 i = 0; i < 100; i++) {
            if ((packedArt >> i) & 1 == 1) {
                result[i] = bytes1('1');
            } else {
                result[i] = bytes1('0');
            }
        }
        return result;
    }
}