// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "../money/Found.sol";
import "../found/FoundNote.sol";

contract UtilV1 {
    using Strings for uint;

    Found private _found;
    FoundNote private _note;

    function profile(address addr) external view returns (string memory) {
        return string(abi.encodePacked(
            '{"address":"', _encodeAddress(addr), '"',
            _encodeBalance(addr),
            '}'
        ));
    }

    function noteStats() external view returns (string memory) {
        uint currentDay = _note.currentDay();

        return string(abi.encodePacked(
            '{"currentDay":', currentDay.toString(),
            _encodeTime(),
            _encodeCash(currentDay),
            _encodeNotes(),
            _encodeFound(),
            '}'
        ));
    }

    function _encodeAddress(address addr) internal pure returns (string memory) {
        return uint(uint160(addr)).toHexString();
    }

    function _encodeDecimals(uint num) internal pure returns (bytes memory) {
        return abi.encodePacked((num / 1e18).toString(), '.', (num % 1e18).toString());
    }

    function _encodeBalance(address addr) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"foundBalance":', _encodeDecimals(_found.balanceOf(addr)),
            ',"balance":', _encodeDecimals(address(addr).balance)
        );
    }

    function _encodeTime() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"timestamp":', block.timestamp.toString(),
            ',"startTime":', _note.startTime().toString(),
            ',"extendTime":', _note.extendTime().toString(),
            ',"dayLength":', _note.DAY_LENGTH().toString()
        );
    }

    function _encodeCash(uint currentDay) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"cashNow":', _encodeDecimals(_note.cashOnCoin(currentDay)),
            ',"cashDaily":', _encodeDecimals(_note.cashOnCoin(currentDay - 1)),
            ',"cashWeekly":', _encodeDecimals(_note.weeklyAverage()),
            ',"dailyBonus":', _encodeDecimals(_note.dailyBonus()),
            ',"treasuryBalance":', _encodeDecimals(_note.treasuryBalance())
        );
    }

    function _encodeNotes() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"totalNotes":', _note.tokenCount().toString(),
            ',"totalShares":', _encodeDecimals(_note.totalShares()),
            ',"totalDeposits":', _encodeDecimals(_note.totalDeposits()),
            ',"totalIncome":', _encodeDecimals(_note.totalIncome()),
            ',"totalTaxes":', _encodeDecimals(_note.totalTaxes())
        );
    }

    function _encodeFound() internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"foundRate":', _encodeDecimals(_found.foundtoEther(1 ether)),
            ',"foundPresale":', (_found.startTime() + _found.PRESALE()).toString(),
            ',"foundVested":', (_found.startTime() + _found.VESTING()).toString(),
            ',"foundClaim":', _encodeDecimals(_found.totalClaim()),
            ',"foundBonus":', _encodeDecimals(_found.totalBonus()),
            ',"foundSupply":', _encodeDecimals(_found.totalSupply())
        );
    }

    constructor(Found found_, FoundNote note_) {
        _found = found_;
        _note = note_;
    }
}