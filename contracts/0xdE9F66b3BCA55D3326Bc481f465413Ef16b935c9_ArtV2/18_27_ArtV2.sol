// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../foundation/FoundBank.sol";
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

contract ArtV2 is ArtMeta {
    using Strings for uint;
    using Strings for uint8;
    using Strings for uint32;
    using Strings for uint64;
    using Strings for address;

    ArtData private _data;
    FoundBank private _bank;
    mapping(uint => string) private _images;

    event ImageCreated(
        uint indexed artId,
        string image,
        uint timestamp
    );

    function getImage(uint tokenId) external view returns (string memory) {
        return _requireImage(tokenId);
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
        return string(_requireImage(tokenId));
    }

    function tokenImageURI(uint tokenId) external view returns (string memory) {
       return string(_requireImage(tokenId));
    }

    function createArt(ArtParams memory params, string memory image) external returns (uint) {
        return _createArt(params, image);
    }

    function _createArt(ArtParams memory params, string memory image) internal returns (uint) {
        uint artId = _data.createArt(params, ArtMeta(this));
        _images[artId] = image;

        emit ImageCreated(artId, image, block.timestamp);
        return artId;
    }

    function submitAndVote(
        address payer,
        address minter,
        uint amount,
        ArtParams memory params,
        string memory image
    ) external returns (uint) {
        uint artId = _createArt(params, image);
        _bank.vote(CoinVote(payer, minter, artId, amount));
        return artId;
    }

    function _encodeData(uint tokenId) internal virtual view returns (bytes memory) {
        Art memory art = _data.getArt(tokenId);
        string memory image = _requireImage(tokenId);

        return abi.encodePacked(
            '{"id":', tokenId.toString(),
            _encodeArt(art),
            ',"delegate":', EncoderV1.encodeAddress(art.delegate),
            ',"image":"', image,
            '"}'
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

    function _requireImage(uint id) internal view returns (string memory) {
        require(
            id > 0 && id <= _data.tokenCount(),
            "Art not found"
        );
        return _images[id];
    }

    constructor(FoundBank bank_, ArtData data_) {
        _data = data_;
        _bank = bank_;
    }
}