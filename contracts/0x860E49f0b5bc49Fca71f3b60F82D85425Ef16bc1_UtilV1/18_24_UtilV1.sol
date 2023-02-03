// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "../foundation/FoundNote.sol";
import "../money/Found.sol";
import "./EncoderV1.sol";

contract UtilV1 {
    using Strings for uint;

    Found private _found;
    FoundNote private _note;

    function profile(address addr) external view returns (string memory) {
        return string(abi.encodePacked(
            '{"address":"', EncoderV1.encodeAddress(addr), '"',
            _encodeBalance(addr),
            '}'
        ));
    }

    function noteStats() external view returns (string memory) {
        uint currentDay = _note.currentDay();

        return string(abi.encodePacked(
            '{"currentDay":', currentDay.toString(),
            _encodeTime(),
            _encodeConstants(),
            _encodeCash(currentDay),
            _encodeNotes(),
            _encodeFound(),
            '}'
        ));
    }

    function _encodeBalance(address addr) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"foundBalance":', EncoderV1.encodeDecimals(_found.balanceOf(addr)),
            ',"balance":', EncoderV1.encodeDecimals(address(addr).balance)
        );
    }

    function _encodeTime() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"timestamp":', block.timestamp.toString(),
            ',"startTime":', _note.startTime().toString(),
            ',"leapSeconds":', _note.leapSeconds().toString()
        );
    }

    function _encodeConstants() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"dayLength":', _note.DAY_LENGTH().toString(),
            ',"lateDuration":', _note.LATE_DURATION().toString(),
            ',"earnWindow":', _note.EARN_WINDOW().toString()
        );
    }

    function _encodeCash(uint currentDay) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"cashNow":', EncoderV1.encodeDecimals(_note.coinRevenue(currentDay)),
            ',"cashDaily":', EncoderV1.encodeDecimals(_note.coinRevenue(currentDay - 1)),
            ',"cashWeekly":', EncoderV1.encodeDecimals(_note.averageRevenue()),
            ',"dailyBonus":', EncoderV1.encodeDecimals(_note.dailyBonus()),
            ',"treasuryBalance":', EncoderV1.encodeDecimals(_note.treasuryBalance())
        );
    }

    function _encodeNotes() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"totalNotes":', _note.tokenCount().toString(),
            ',"totalShares":', EncoderV1.encodeDecimals(_note.totalShares()),
            ',"totalDeposits":', EncoderV1.encodeDecimals(_note.totalDeposits()),
            ',"totalEarnings":', EncoderV1.encodeDecimals(_note.totalEarnings()),
            ',"totalFunding":', EncoderV1.encodeDecimals(_note.totalFunding())
        );
    }

    function _encodeFound() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"foundRate":', EncoderV1.encodeDecimals(_found.convert(1 ether)),
            ',"foundClaim":', EncoderV1.encodeDecimals(_found.totalClaim()),
            ',"foundSupply":', EncoderV1.encodeDecimals(_found.totalSupply())
        );
    }

    constructor(Found found_, FoundNote note_) {
        _found = found_;
        _note = note_;
    }
}