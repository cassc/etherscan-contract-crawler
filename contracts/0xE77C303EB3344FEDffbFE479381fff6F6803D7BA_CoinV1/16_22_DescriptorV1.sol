// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/Base64.sol";
import "../art/ArtData.sol";
import "./EncoderV1.sol";

abstract contract DescriptorV1 is ArtMeta {
    using Strings for uint;
    ArtData private _data;

    function _encodeData(uint tokenId) internal virtual view returns (bytes memory);
    function _encodeArtId(uint tokenId) internal virtual view returns (uint);

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
        return _data.tokenImage(_encodeArtId(tokenId));
    }

    function tokenImageURI(uint tokenId) external view returns (string memory) {
        return _data.tokenImageURI(_encodeArtId(tokenId));
    }

    function _encodeInfo(uint artId) internal virtual view returns (bytes memory) {
        Art memory art = _data.getArt(artId);
        return abi.encodePacked(
            ',"name":"', art.name,
            '","symbol":"', art.symbol,
            '","color1":"', EncoderV1.encodeColor(art.color1),
            '","color2":"', EncoderV1.encodeColor(art.color2),
            '","description":"', art.description,
            _encodeMetaData(art)
        );
    }

    function _encodeMetaData(Art memory art) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            '","image":"', _data.tokenImageURI(art.id),
            '","delegate":', EncoderV1.encodeAddress(art.delegate),
            ',"meta":', EncoderV1.encodeAddress(address(this)),
            ',"artId":', art.id.toString()
        );
    }

    constructor(ArtData data_) {
        _data = data_;
    }
}