// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "../found/FoundNote.sol";
import "./EncoderV1.sol";

contract NoteV1 is EncoderV1 {
    using Strings for uint;

    FoundNote private _note;

    function tokenCount() external view returns (uint) {
        return _note.tokenCount();
    }

    function _encodeArtId(uint tokenId) override internal view returns (uint) {
        return _note.getNote(tokenId).artId;
    }

    function _encodeData(uint tokenId) override internal view returns (bytes memory) {
        Note memory note = _note.getNote(tokenId);

        return abi.encodePacked(
            '{"id":', tokenId.toString(),
            _encodeInfo(note.artId),
            _encodeStats(note),
            _encodeDates(note),
            '}'
        );
    }

    function _encodeStats(Note memory note) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"dailyBonus":', _encodeDecimals(note.dailyBonus),
            ',"govt":', note.govt.toString(),
            ',"tax":', note.tax.toString(),
            _encodeNoteStats(note)
        );
    }

    function _encodeNoteStats(Note memory note) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"shares":', _encodeDecimals(note.shares),
            ',"principal":', _encodeDecimals(note.principal),
            ',"penalty":', _encodeDecimals(note.penalty),
            ',"income":', _encodeDecimals(note.income),
            ',"taxes":', _encodeDecimals(note.taxes)
        );
    }

    function _encodeDates(Note memory note) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"memo":"', note.memo,
            '","duration":', note.duration.toString(),
            ',"expiresAt":', note.expiresAt.toString(),
            ',"createdAt":', note.createdAt.toString(),
            ',"collectedAt":', note.collectedAt.toString(),
            ',"closed":', note.closed ? 'true' : 'false'
        );
    }

    constructor(ArtData data_, FoundNote note_) EncoderV1(data_) {
        _note = note_;
    }
}