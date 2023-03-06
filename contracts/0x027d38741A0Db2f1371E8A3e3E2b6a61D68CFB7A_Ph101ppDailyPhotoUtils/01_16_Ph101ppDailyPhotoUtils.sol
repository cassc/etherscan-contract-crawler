// SPDX-License-Identifier: MIT
// Author: Philipp Adrian (ph101pp.eth)
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ERC1155MintRangeUpdateable.sol";

import "hardhat/console.sol";

library Ph101ppDailyPhotoUtils {
    uint256 constant SECONDS_PER_DAY = 1 days;
    int256 constant OFFSET19700101 = 2440588;
    uint public constant START_DATE = 1661990400; // Sept 1, 2022
    uint public constant CLAIM_TOKEN_ID = 0;
    string private constant _CLAIM_TOKEN = "CLAIM";

    ///////////////////////////////////////////////////////////////////////////
    // DateTime
    ///////////////////////////////////////////////////////////////////////////

    // ----------------------------------------------------------------------------
    // DateTime Library v2.0
    //
    // A gas-efficient Solidity date and time library
    //
    // https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
    //
    // Tested date range 1970/01/01 to 2345/12/31
    //
    // Conventions:
    // Unit      | Range         | Notes
    // :-------- |:-------------:|:-----
    // timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
    // year      | 1970 ... 2345 |
    // month     | 1 ... 12      |
    // day       | 1 ... 31      |
    // hour      | 0 ... 23      |
    // minute    | 0 ... 59      |
    // second    | 0 ... 59      |
    // dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
    //
    //
    // Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
    // ----------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(
        uint256 _days
    ) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) external pure returns (uint256 timestamp) {
        return _timestampFromDate(year, month, day);
    }

    function _timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampToDate(
        uint256 timestamp
    ) external pure returns (uint256 year, uint256 month, uint256 day) {
        return _timestampToDate(timestamp);
    }

    function _timestampToDate(
        uint256 timestamp
    ) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) external pure returns (bool valid) {
        return _isValidDate(year, month, day);
    }

    function _isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function _getDaysInMonth(
        uint256 year,
        uint256 month
    ) internal pure returns (uint256 daysInMonth) {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    ///////////////////////////////////////////////////////////////////////////
    // TokenSlug
    ///////////////////////////////////////////////////////////////////////////

    function tokenSlugFromTokenId(
        uint tokenId
    ) external pure returns (string memory tokenSlug) {
        if (tokenId == CLAIM_TOKEN_ID) {
            return
                string.concat(
                    _CLAIM_TOKEN,
                    "-",
                    Strings.toString(CLAIM_TOKEN_ID)
                );
        }
        (uint year, uint month, uint day) = _timestampToDate(
            START_DATE + ((tokenId - 1) * 1 days)
        );
        return _tokenSlug(tokenId, year, month, day);
    }

    function tokenSlugFromDate(
        uint year,
        uint month,
        uint day
    ) external pure returns (string memory tokenSlug) {
        require(_isValidDate(year, month, day), "Invalid date!");
        uint tokenTimestamp = _timestampFromDate(year, month, day);
        require(
            tokenTimestamp >= START_DATE,
            "Project started September 1, 2022!"
        );
        return
            _tokenSlug(
                (((tokenTimestamp - START_DATE) / 1 days) + 1),
                year,
                month,
                day
            );
    }

    function _tokenSlug(
        uint tokenId,
        uint year,
        uint month,
        uint day
    ) private pure returns (string memory tokenSlug) {
        return
            string.concat(
                Strings.toString(year),
                month <= 9 ? "0" : "",
                Strings.toString(month),
                day <= 9 ? "0" : "",
                Strings.toString(day),
                "-",
                Strings.toString(tokenId)
            );
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC1155MintRangeUpdateable
    ///////////////////////////////////////////////////////////////////////////

    // Verifies input to updateInitialHolders function
    function verifyUpdateInitialHoldersInput(
        ERC1155MintRangeUpdateable.VerifyUpdateInitialHoldersInput memory p
    ) external view returns (bytes32) {
        uint lastRangeTokenIdMinted = p.caller.lastRangeTokenIdMinted();
        require(
            // range must to start at 0
            p.newInitialHolderRanges[0] == 0 &&
                // and end before last minted id
                p.newInitialHolderRanges[p.newInitialHolderRanges.length - 1] <=
                lastRangeTokenIdMinted &&
                // amount of ranges & initialHolders must match
                p.newInitialHolderRanges.length == p.newInitialHolders.length,
            "U:01"
        );
        require(p.fromAddresses.length == p.toAddresses.length, "U:02");
        require(p.fromAddresses.length == p.ids.length, "U:03");
        require(p.fromAddresses.length == p.amounts.length, "U:04");

        for (uint i = 1; i < p.newInitialHolderRanges.length; i++) {
            require(
                p.newInitialHolderRanges[i] > p.newInitialHolderRanges[i - 1],
                "U:05"
            );
        }

        uint[] memory txTokenIndex = new uint[](p.fromAddresses.length);

        if (p.caller.isZeroMinted()) {
            for (
                uint tokenId = 0;
                tokenId <= lastRangeTokenIdMinted;
                tokenId++
            ) {
                address[] memory currentHolders = p.caller.initialHolders(
                    tokenId
                );
                address[] memory newHolders = p.newInitialHolders[
                    _findLowerBound(p.newInitialHolderRanges, tokenId)
                ];

                bool isLocked = p.caller.isZeroLocked() &&
                    p.caller.lastRangeTokenIdWithLockedInitialHolders() >=
                    tokenId;

                if (p.caller.isManualMint(tokenId)) {
                    continue;
                }
                require(newHolders.length == currentHolders.length, "U:06");

                uint[] memory ids = new uint[](newHolders.length);
                for (uint k = 0; k < newHolders.length; k++) {
                    ids[k] = tokenId;
                }

                uint[] memory balancesOld = p.caller.balanceOfBatch(
                    currentHolders,
                    ids
                );

                for (uint a = 0; a < newHolders.length; a++) {
                    // address fromAddress = currentHolders[a];
                    // address toAddress = newHolders[a];

                    // No duplicate address for tokenID
                    for (uint b = a + 1; b < newHolders.length; b++) {
                        require(newHolders[a] != newHolders[b], "U:07");
                    }

                    if (currentHolders[a] == newHolders[a]) {
                        continue;
                    }
                    require(newHolders[a] != address(0), "U:08");
                    require(!isLocked, "U:09");
                    require(
                        !p.caller.isHolderAddress(newHolders[a]) ||
                            p.caller.isInitialHolderAddress(newHolders[a]),
                        "U:10"
                    );

                    uint txIndex;
                    bool txFound;

                    for (uint x = 0; x < p.fromAddresses.length; x++) {
                        if (
                            p.fromAddresses[x] == currentHolders[a] &&
                            p.toAddresses[x] == newHolders[a]
                        ) {
                            txIndex = x;
                            txFound = true;
                            break;
                        }
                    }
                    require(txFound, "U:11");

                    if (
                        !p.caller.isBalanceInitialized(
                            currentHolders[a],
                            tokenId
                        ) &&
                        !p.caller.isBalanceInitialized(
                            newHolders[a],
                            tokenId
                        ) 
                    ) {
                        require(
                            currentHolders[a] == p.fromAddresses[txIndex],
                            "U:12"
                        );
                        require(newHolders[a] == p.toAddresses[txIndex], "U:13");
                        require(
                            tokenId == p.ids[txIndex][txTokenIndex[txIndex]],
                            "U:14"
                        );
                        require(
                            balancesOld[a] ==
                                p.amounts[txIndex][txTokenIndex[txIndex]],
                            "U:15"
                        );
                        txTokenIndex[txIndex]++;
                    }
                }
            }
        }

        for (uint x = 0; x < p.fromAddresses.length; x++) {
            require(txTokenIndex[x] == p.ids[x].length, "U:16");
        }

        (
            address[][] memory _initialHolders,
            uint[] memory _initialHolderRanges
        ) = p.caller.initialHolderRanges();

        return
            keccak256(
                abi.encode(
                    ERC1155MintRangeUpdateable.UpdateInitialHoldersInput(
                        p.fromAddresses,
                        p.toAddresses,
                        p.ids,
                        p.amounts,
                        p.newInitialHolders,
                        p.newInitialHolderRanges
                    ),
                    _initialHolders,
                    _initialHolderRanges,
                    p.caller.paused()
                )
            );
    }

    // Utility to find lower bound. 
    // Returns index of last element that is small 
    // than given element in a sorted array.
    function _findLowerBound(
        uint256[] memory array,
        uint256 element
    ) private pure returns (uint256) {
        for (uint i = array.length - 1; i >= 0; i--) {
            if (element >= array[i]) {
                return i;
            }
        }
        return 0;
    }

    // Utility to find Address in array of addresses
    function _includesAddress(
        address[] memory array,
        address value
    ) private pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }
}