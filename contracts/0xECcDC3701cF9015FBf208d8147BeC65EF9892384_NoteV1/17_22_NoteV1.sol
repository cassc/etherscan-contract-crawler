// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "../foundation/FoundNote.sol";
import "./DescriptorV1.sol";

contract NoteV1 is DescriptorV1 {
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
            _encodeDelegation(note),
            '}'
        );
    }

    function _encodeStats(Note memory note) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"dailyBonus":', EncoderV1.encodeDecimals(note.dailyBonus),
            ',"fund":', note.fund.toString(),
            ',"reward":', note.reward.toString(),
            _encodeNoteStats(note)
        );
    }

    function _encodeNoteStats(Note memory note) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"shares":', EncoderV1.encodeDecimals(note.shares),
            ',"principal":', EncoderV1.encodeDecimals(note.principal),
            ',"penalty":', EncoderV1.encodeDecimals(note.penalty),
            ',"earnings":', EncoderV1.encodeDecimals(note.earnings),
            ',"funding":', EncoderV1.encodeDecimals(note.funding)
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

    function _encodeDelegation(Note memory note) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"delegate":', EncoderV1.encodeAddress(note.delegate),
            ',"payee":', EncoderV1.encodeAddress(note.payee)
        );
    }

    constructor(ArtData data_, FoundNote note_) DescriptorV1(data_) {
        _note = note_;
    }
}