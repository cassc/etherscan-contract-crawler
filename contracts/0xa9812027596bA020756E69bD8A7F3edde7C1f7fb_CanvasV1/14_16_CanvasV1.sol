// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../descriptors/EncoderV1.sol";
import "../foundation/IFoundBank.sol";
import "../art/ArtData.sol";

  /*$$$$$  /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$$ /$$$$$$ /$$    /$$ /$$$$$$$$
 /$$__  $$| $$__  $$| $$_____/ /$$__  $$|__  $$__/|_  $$_/| $$   | $$| $$_____/
| $$  \__/| $$  \ $$| $$      | $$  \ $$   | $$     | $$  | $$   | $$| $$
| $$      | $$$$$$$/| $$$$$   | $$$$$$$$   | $$     | $$  |  $$ / $$/| $$$$$
| $$      | $$__  $$| $$__/   | $$__  $$   | $$     | $$   \  $$ $$/ | $$__/
| $$    $$| $$  \ $$| $$      | $$  | $$   | $$     | $$    \  $$$/  | $$
|  $$$$$$/| $$  | $$| $$$$$$$$| $$  | $$   | $$    /$$$$$$   \  $/   | $$$$$$$$
 \______/ |__/  |__/|________/|__/  |__/   |__/   |______/    \_/    |_______*/

struct CanvasImageV1 {
    string imageUrl;
    uint64[] shapes;
}

contract CanvasV1 is ArtMeta {
    using Strings for uint;
    using Strings for uint8;
    using Strings for uint32;
    using Strings for uint64;
    using Strings for address;

    ArtData private _data;
    IFoundBank private _bank;

    event ImageCreated(
        uint indexed artId,
        string imageUrl,
        uint timestamp
    );

    event ImageUpdated(
        uint indexed artId,
        string imageUrl,
        uint timestamp
    );

    event ImageLocked(
        uint indexed artId,
        uint timestamp
    );

    mapping(uint => bool) private _locks;
    mapping(uint => CanvasImageV1) private _images;

    function data() external view returns (ArtData) {
        return _data;
    }

    function bank() external view returns (IFoundBank) {
        return _bank;
    }

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

    function createArt(
        ArtParams calldata params,
        CanvasImageV1 calldata image
    ) external returns (uint) {
        return _createArt(params, image);
    }

    function submitAndVote(
        address payer,
        address minter,
        uint amount,
        ArtParams calldata params,
        CanvasImageV1 calldata image
    ) external returns (uint) {
        uint artId = _createArt(params, image);
        _bank.vote(CoinVote(payer, minter, artId, amount));
        return artId;
    }

    function _createArt(
        ArtParams memory params,
        CanvasImageV1 memory image
    ) internal returns (uint) {
        uint artId = _data.createArt(params, ArtMeta(this));

        CanvasImageV1 storage img = _images[artId];
        img.imageUrl = image.imageUrl;
        img.shapes = image.shapes;

        emit ImageCreated(
            artId,
            image.imageUrl,
            block.timestamp
        );

        return artId;
    }

    function updateArt(
        uint artId,
        CanvasImageV1 calldata image
    ) external returns (uint) {
        require(
            msg.sender == _data.ownerOf(artId),
            "Caller is not the owner"
        );

        require(
            !_locks[artId],
            "Artwork has been locked"
        );

        CanvasImageV1 storage img = _images[artId];
        img.imageUrl = image.imageUrl;
        img.shapes = image.shapes;

        emit ImageUpdated(
            artId,
            image.imageUrl,
            block.timestamp
        );

        return artId;
    }

    function lockArt(uint artId) external returns (uint) {
        require(
            msg.sender == _data.ownerOf(artId),
            "Caller is not the owner"
        );

        _locks[artId] = true;

        emit ImageLocked(
            artId,
            block.timestamp
        );

        return artId;
    }

    function getImage(uint tokenId) external view returns (CanvasImageV1 memory) {
        return _requireImage(tokenId);
    }

    function _encodeData(uint tokenId) internal virtual view returns (bytes memory) {
        Art memory art = _data.getArt(tokenId);
        CanvasImageV1 memory img = _requireImage(tokenId);
        bool locked = _locks[tokenId];

        return abi.encodePacked(
            '{"id":', tokenId.toString(),
            _encodeArt(art),
            ',"descriptor":', EncoderV1.encodeAddress(address(this)),
            ',"delegate":', EncoderV1.encodeAddress(art.delegate),
            ',"locked":', locked ? 'true' : 'false',
            ',"imageUrl":"', img.imageUrl,
            _encodeImage(img),
            '"}'
        );
    }

    function _encodeImage(CanvasImageV1 memory img) internal virtual view returns (bytes memory) {
        if (img.shapes.length > 0) {
            return abi.encodePacked(
                '","shapes":[', _encodeShapes(img),
                '],"image":"', _encodeSVGURI(img)
            );
        }

        return abi.encodePacked(
            '","image":"', img.imageUrl
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

    function _encodeSVGURI(CanvasImageV1 memory image) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            'data:image/svg+xml;base64,',
            Base64.encode(_encodeSVG(image))
        );
    }

    function _requireImage(uint id) internal view returns (CanvasImageV1 memory) {
        require(
            id > 0 && id <= _data.tokenCount(),
            "Art not found"
        );
        return _images[id];
    }

      /*$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$  /$$$$$$$$  /$$$$$$
     /$$__  $$| $$  | $$ /$$__  $$| $$__  $$| $$_____/ /$$__  $$
    | $$  \__/| $$  | $$| $$  \ $$| $$  \ $$| $$      | $$  \__/
    |  $$$$$$ | $$$$$$$$| $$$$$$$$| $$$$$$$/| $$$$$   |  $$$$$$
     \____  $$| $$__  $$| $$__  $$| $$____/ | $$__/    \____  $$
     /$$  \ $$| $$  | $$| $$  | $$| $$      | $$       /$$  \ $$
    |  $$$$$$/| $$  | $$| $$  | $$| $$      | $$$$$$$$|  $$$$$$/
     \______/ |__/  |__/|__/  |__/|__/      |________/ \_____*/

    function _encodeSVG(CanvasImageV1 memory image) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<svg width="512" height="512" viewBox="0 0 255 255" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
            string(_encodeSVGShapes(image)),
            '</svg>'
        );
    }

    function _encodeShapes(CanvasImageV1 memory image) internal pure returns (bytes memory) {
        bytes memory out;
        uint l = image.shapes.length;

        for (uint i = 0; i < l - 1; i += 1) {
            out = abi.encodePacked(out, image.shapes[i].toString(), ",");
        }

        return abi.encodePacked(out, image.shapes[l - 1].toString());
    }

    function _encodeSVGShapes(CanvasImageV1 memory image) internal pure returns (bytes memory) {
        bytes memory out;
        uint l = image.shapes.length;

        for (uint i = 0; i < l; i += 1) {
            out = abi.encodePacked(out, _encodeSVGShape(image.shapes[i]));
        }

        return out;
    }

    function _encodeSVGShape(uint64 part) internal pure returns (bytes memory) {
        uint8 t = uint8(part >> 56);

        if (t == 0) {
            return _encodeSVGRect(part);
        } if (t == 1) {
            return _encodeSVGEllipse(part);
        }

        return _encodeSVGLine(part, t - 1);
    }

    function _encodeSVGLine(uint64 part, uint8 thickness) internal pure returns (bytes memory) {
        uint8 x1 = uint8(part >> 48);
        uint8 y1 = uint8(part >> 40);
        uint8 x2 = uint8(part >> 32);
        uint8 y2 = uint8(part >> 24);

        return abi.encodePacked(
            '<line x1="', x1.toString(),
            '" y1="', y1.toString(),
            '" x2="', x2.toString(),
            '" y2="', y2.toString(),
            '" stroke="', _encodeSVGColor(part),
            '" stroke-width="', thickness.toString(),
            '" stroke-linecap="round"/>'
        );
    }

    function _encodeSVGEllipse(uint64 part) internal pure returns (bytes memory) {
        uint8 cx = uint8(part >> 48);
        uint8 cy = uint8(part >> 40);
        uint8 rx = uint8(part >> 32);
        uint8 ry = uint8(part >> 24);

        return abi.encodePacked(
            '<ellipse cx="', cx.toString(),
            '" cy="', cy.toString(),
            '" rx="', rx.toString(),
            '" ry="', ry.toString(),
            '" fill="', _encodeSVGColor(part),
            '"/>'
        );
    }

    function _encodeSVGRect(uint64 part) internal pure returns (bytes memory) {
        uint8 w = uint8(part >> 48);
        uint8 h = uint8(part >> 40);
        uint8 x = uint8(part >> 32);
        uint8 y = uint8(part >> 24);

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
        uint8 r = uint8(part >> 16);
        uint8 g = uint8(part >> 8);
        uint8 b = uint8(part);

        return abi.encodePacked(
            'rgb(',
                r.toString(), ',',
                g.toString(), ',',
                b.toString(),
            ')'
        );
    }

    constructor(IFoundBank bank_, ArtData data_) {
        _bank = bank_;
        _data = data_;
    }
}