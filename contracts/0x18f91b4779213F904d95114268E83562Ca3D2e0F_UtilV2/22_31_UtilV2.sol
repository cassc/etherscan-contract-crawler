// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "../foundation/FoundNote.sol";
import "../cash/CashPrinter.sol";
import "../money/Found.sol";
import "./EncoderV1.sol";

contract UtilV2 {
    using Strings for uint;

    Cash private _cash;
    Found private _found;
    FoundNote private _note;
    CashPrinter private _printer;

    function found() external view returns (Found) {
        return _found;
    }

    function note() external view returns (FoundNote) {
        return _note;
    }

    function printer() external view returns (CashPrinter) {
        return _printer;
    }

    function profile(address addr) external view returns (string memory) {
        return string(abi.encodePacked(
            '{"address":"', EncoderV1.encodeAddress(addr), '"',
            _encodeBalance(addr),
            '}'
        ));
    }

    function bankStats() external view returns (string memory) {
        uint currentDay = _note.currentDay();

        return string(abi.encodePacked(
            '{"currentDay":', currentDay.toString(),
            _encodeTime(),
            _encodeConstants(),
            _encodeLeader(currentDay),
            _encodeRevenue(currentDay),
            _encodeNotes(),
            _encodeCash(),
            _encodeFound(),
            '}'
        ));
    }

    function _encodeBalance(address addr) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"foundBalance":', EncoderV1.encodeDecimals(_found.balanceOf(addr)),
            ',"cashBalance":', EncoderV1.encodeDecimals(_cash.balanceOf(addr)),
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

    function _encodeLeader(uint currentDay) internal virtual view returns (bytes memory) {
        uint topArtId = _note.coinToArt(currentDay);
        return abi.encodePacked(
            ',"topArtId":', topArtId.toString(),
            ',"topArtVotes":', EncoderV1.encodeDecimals(_note.votesOnArt(currentDay, topArtId)),
            ',"revenueYesterday":', EncoderV1.encodeDecimals(_note.coinRevenue(currentDay - 1)),
            ',"revenueAverage":', EncoderV1.encodeDecimals(_note.averageRevenue()),
            ',"dailyBonus":', EncoderV1.encodeDecimals(_note.dailyBonus()),
            ',"treasuryBalance":', EncoderV1.encodeDecimals(_note.treasuryBalance())
        );
    }

    function _encodeRevenue(uint currentDay) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"revenueToday":', EncoderV1.encodeDecimals(_note.coinRevenue(currentDay)),
            ',"revenueYesterday":', EncoderV1.encodeDecimals(_note.coinRevenue(currentDay - 1)),
            ',"revenueAverage":', EncoderV1.encodeDecimals(_note.averageRevenue()),
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

    function _encodeCash() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"totalStakes":', _printer.tokenCount().toString(),
            ',"totalStaked":', EncoderV1.encodeDecimals(_printer.totalStaked()),
            ',"totalCash":', EncoderV1.encodeDecimals(_printer.totalCash()),
            ',"totalStakeShares":', EncoderV1.encodeDecimals(_printer.totalShares())
        );
    }

    function _encodeFound() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"foundRate":', EncoderV1.encodeDecimals(_found.convert(1 ether)),
            ',"foundClaim":', EncoderV1.encodeDecimals(_found.totalClaim()),
            ',"foundSupply":', EncoderV1.encodeDecimals(_found.totalSupply())
        );
    }

    constructor(Found found_, FoundNote note_, CashPrinter printer_) {
        _printer = printer_;
        _found = found_;
        _note = note_;
        _cash = _printer.cash();
    }
}