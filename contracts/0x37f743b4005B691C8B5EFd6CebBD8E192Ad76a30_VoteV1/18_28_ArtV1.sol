// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../art/ArtData.sol";
import "./EncoderV1.sol";

  /*$$$$$  /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$$ /$$$$$$ /$$    /$$ /$$$$$$$$
 /$$__  $$| $$__  $$| $$_____/ /$$__  $$|__  $$__/|_  $$_/| $$   | $$| $$_____/
| $$  \__/| $$  \ $$| $$      | $$  \ $$   | $$     | $$  | $$   | $$| $$
| $$      | $$$$$$$/| $$$$$   | $$$$$$$$   | $$     | $$  |  $$ / $$/| $$$$$
| $$      | $$__  $$| $$__/   | $$__  $$   | $$     | $$   \  $$ $$/ | $$__/
| $$    $$| $$  \ $$| $$      | $$  | $$   | $$     | $$    \  $$$/  | $$
|  $$$$$$/| $$  | $$| $$$$$$$$| $$  | $$   | $$    /$$$$$$   \  $/   | $$$$$$$$
 \______/ |__/  |__/|________/|__/  |__/   |__/   |______/    \_/    |_______*/

struct ImageV1 {
    uint64[] shapes;
}

contract ArtV1 is ArtMeta {
    using Strings for uint;
    using Strings for uint8;
    using Strings for uint32;
    using Strings for uint64;
    using Strings for address;

    ArtData private _data;

    event ImageCreated(
        uint indexed artId,
        uint timestamp
    );

    mapping(uint => ImageV1) private _image;

    function tokenCount() external view returns (uint) {
        return _data.tokenCount();
    }

    function tokenData(uint tokenId) external view returns (string memory) {
        return string(_encodeData(tokenId));
    }

    function tokenDataURI(uint tokenId) external view returns (string memory) {
        return string(
             abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(_encodeData(tokenId))
            )
        );
    }

    function tokenImage(uint tokenId) external view returns (string memory) {
        return string(_encodeSVG(_requireImage(tokenId)));
    }

    function tokenImageURI(uint tokenId) external view returns (string memory) {
       return string(_encodeSVGURI(_requireImage(tokenId)));
    }

    function createArt(ArtParams memory params, ImageV1 memory image) external returns (uint) {
        uint artId = _data.createArt(params, ArtMeta(this));

        ImageV1 storage img = _image[artId];
        img.shapes = image.shapes;

        emit ImageCreated(artId, block.timestamp);
        return artId;
    }

    function getImage(uint tokenId) external view returns (ImageV1 memory) {
        return _requireImage(tokenId);
    }

    function _encodeData(uint tokenId) internal virtual view returns (bytes memory) {
        Art memory art = _data.getArt(tokenId);
        ImageV1 memory data = _requireImage(tokenId);

        return abi.encodePacked(
            '{"id":', tokenId.toString(),
            _encodeArt(art),
            ',"delegate":', EncoderV1.encodeAddress(art.delegate),
            ',"image":"', _encodeSVGURI(data),
            '","shapes":[', _encodeShapes(data),
            ']}'
        );
    }

    function _encodeArt(Art memory art) internal pure returns (bytes memory) {
        return abi.encodePacked(
            ',"name":"', art.name,
            '","symbol":"', art.symbol,
            '","color1":"', EncoderV1.encodeColor(art.color1),
            '","color2":"', EncoderV1.encodeColor(art.color2),
            '","description":"', art.description,
            '","createdAt":', art.createdAt.toString()
        );
    }

    function _encodeSVGURI(ImageV1 memory image) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            'data:image/svg+xml;base64,',
            Base64.encode(_encodeSVG(image))
        );
    }

    function _requireImage(uint id) internal view returns (ImageV1 memory) {
        require(
            id > 0 && id <= _data.tokenCount(),
            "Art not found"
        );
        return _image[id];
    }

      /*$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$  /$$$$$$$$  /$$$$$$
     /$$__  $$| $$  | $$ /$$__  $$| $$__  $$| $$_____/ /$$__  $$
    | $$  \__/| $$  | $$| $$  \ $$| $$  \ $$| $$      | $$  \__/
    |  $$$$$$ | $$$$$$$$| $$$$$$$$| $$$$$$$/| $$$$$   |  $$$$$$
     \____  $$| $$__  $$| $$__  $$| $$____/ | $$__/    \____  $$
     /$$  \ $$| $$  | $$| $$  | $$| $$      | $$       /$$  \ $$
    |  $$$$$$/| $$  | $$| $$  | $$| $$      | $$$$$$$$|  $$$$$$/
     \______/ |__/  |__/|__/  |__/|__/      |________/ \_____*/

    function _encodeSVG(ImageV1 memory image) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<svg width="420" height="420" viewBox="0 0 255 255" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
            string(_encodeSVGShapes(image)),
            '</svg>'
        );
    }

    function _encodeShapes(ImageV1 memory image) internal pure returns (bytes memory) {
        bytes memory out;
        uint l = image.shapes.length;

        for (uint i = 0; i < l - 1; i += 1) {
            out = abi.encodePacked(out, image.shapes[i].toString(), ",");
        }

        return abi.encodePacked(out, image.shapes[l - 1].toString());
    }

    function _encodeSVGShapes(ImageV1 memory image) internal pure returns (bytes memory) {
        bytes memory out;
        uint l = image.shapes.length;

        for (uint i = 0; i < l; i += 1) {
            out = abi.encodePacked(out, _encodeSVGRect(image.shapes[i]));
        }

        return out;
    }

    function _encodeSVGRect(uint64 part) internal pure returns (bytes memory) {
        uint8 w = uint8(part >> 56);
        uint8 h = uint8(part >> 48);
        uint8 x = uint8(part >> 40);
        uint8 y = uint8(part >> 32);

        return abi.encodePacked(
            '<rect width="', w.toString(),
            '" height="', h.toString(),
            '" x="', x.toString(),
            '" y="', y.toString(),
            '" fill="', _encodeSVGColor(part),
            '"/>'
        );
    }

    function _encodeSVGColor(uint64 part) internal pure returns (bytes memory) {
        uint8 r = uint8(part >> 24);
        uint8 g = uint8(part >> 16);
        uint8 b = uint8(part >> 8);
        uint8 a = uint8(part);

        return abi.encodePacked(
            'rgba(',
                r.toString(), ',',
                g.toString(), ',',
                b.toString(), ',',
                a.toString(),
            ')'
        );
    }

    constructor(ArtData data_) {
        _data = data_;
    }
}