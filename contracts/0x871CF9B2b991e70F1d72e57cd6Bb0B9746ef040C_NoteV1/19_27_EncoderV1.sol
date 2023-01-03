// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/Base64.sol";
import "../found/ArtData.sol";

abstract contract EncoderV1 is ArtMeta {
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

    function encodeDecimals(uint num) external pure returns (string memory) {
        return string(_encodeDecimals(num));
    }

    function _encodeDecimals(uint num) internal pure returns (bytes memory) {
        bytes memory decimals = bytes((num % 1e18).toString());
        uint length = decimals.length;

        for (uint i = length; i < 18; i += 1) {
            decimals = abi.encodePacked('0', decimals);
        }        
        
        return abi.encodePacked(
            (num / 1e18).toString(), 
            '.',
            decimals
        );
    }

    function _encodeInfo(uint artId) internal virtual view returns (bytes memory) {
        Art memory art = _data.getArt(artId);
        return abi.encodePacked(
            ',"name":"', art.name,
            '","symbol":"', art.symbol,
            '","color1":"', art.color1,
            '","color2":"', art.color2,
            '","description":"', art.description,
            _encodeMetaData(art)
        );
    }

    function _encodeMetaData(Art memory art) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            '","image":"', _data.tokenImageURI(art.id),
            '","delegate":"', uint(uint160(address(art.delegate))).toHexString(),
            '","metadata":"', uint(uint160(address(this))).toHexString(),
            '","artId":', art.id.toString()
        );
    }

    constructor(ArtData data_) {
        _data = data_;
    }
}