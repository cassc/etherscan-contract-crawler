// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

contract BillingDate {
    uint256 constant DENOMINATOR = 10_000;

    /**
     * parse timestamp & get service params for calculations
     */
    function getDaysFromTimestamp(uint256 timestamp)
        public
        pure
        returns (
            uint256 daysFrom0,
            uint256 yearStartDay,
            uint256 dayOfYear,
            uint256 yearsFrom1972
        )
    {
        // get number of days from seconds
        daysFrom0 = (timestamp * DENOMINATOR) / 86_400 / DENOMINATOR;

        // get number of full years from `01.01.1970 + 730 days = 01.01.1972` (first leap year from 1970)
        yearsFrom1972 =
            ((((daysFrom0 - 730) * DENOMINATOR) / 1461) * 4) /
            DENOMINATOR;

        // subtract 1 year from numOfYears (so 0 year = 01.01.1973) and add 1096 days (= 366 + 365 + 365 days) so 0 years is 01.01.1970 so we can get 0 day of the year
        yearStartDay = ((((yearsFrom1972 - 1) * 1461) / 4) + 1096);

        dayOfYear = daysFrom0 - yearStartDay + 1;
    }

    /**
     * parse date info from timestamp
     */
    function parseTimestamp(uint256 timestamp)
        public
        pure
        returns (
            uint256 date,
            uint256 month,
            uint256 year,
            uint256 daysInMonth
        )
    {
        (, , uint256 dayOfYear, uint256 yearsFrom1972) = getDaysFromTimestamp(
            timestamp
        );

        year = 1972 + yearsFrom1972;

        uint8[12] memory monthsLengths = [
            31,
            yearsFrom1972 % 4 == 0 ? 29 : 28,
            31,
            30,
            31,
            30,
            31,
            31,
            30,
            31,
            30,
            31
        ];

        for (uint256 index = 0; index < 12; index++) {
            uint256 _daysInMonth = monthsLengths[index];

            if (dayOfYear > _daysInMonth) {
                dayOfYear -= _daysInMonth;
                continue;
            }
            date = dayOfYear;
            month = index + 1;
            daysInMonth = _daysInMonth;
            break;
        }
    }

    /**
     * get timestamp of next billing from current date
     */
    function billingTimestampFromDate(
        uint256 date,
        uint256 month,
        uint256 year
    ) public pure returns (uint256 timestamp) {
        timestamp = (((((year - 1973) * 1461) / 4)) + 1096);
        uint8[12] memory monthsLengths = [
            31,
            (year - 1972) % 4 == 0 ? 29 : 28,
            31,
            30,
            31,
            30,
            31,
            31,
            30,
            31,
            30,
            31
        ];

        for (uint256 index = 0; index < 12; index++) {
            uint256 _daysInMonth = monthsLengths[index];

            if (index + 1 == month) {
                // if days in next month lt current date, next billing date eq end of the next month
                if (date > _daysInMonth) date = _daysInMonth;
                break;
            }
            timestamp += _daysInMonth;
        }
        timestamp += date - 1;
        timestamp *= 86_400;
    }

    /**
     * get current date and next billing timestamp from current timestamp
     */
    function parseBillingTimestamp(uint256 timestamp)
        public
        pure
        returns (uint8 billingDay, uint256 nextBillingTimestamp)
    {
        (
            uint256 daysFrom0,
            ,
            uint256 dayOfYear,
            uint256 yearsFrom1972
        ) = getDaysFromTimestamp(timestamp);

        nextBillingTimestamp = daysFrom0;

        uint8[12] memory monthsLengths = [
            31,
            yearsFrom1972 % 4 == 0 ? 29 : 28,
            31,
            30,
            31,
            30,
            31,
            31,
            30,
            31,
            30,
            31
        ];

        for (uint256 index = 0; index < 12; index++) {
            uint256 daysInMonth = monthsLengths[index];

            if (dayOfYear > daysInMonth) {
                dayOfYear -= daysInMonth;
                continue;
            }
            billingDay = uint8(dayOfYear);

            if (index == 11) {
                nextBillingTimestamp += daysInMonth;
                break;
            }
            uint256 daysInNextMonth = monthsLengths[index + 1];
            /**
             * if billingDay gt daysInNextMonth (billingDay == 31 && daysInNextMonth == 28)
             * expiration date will be next month's last day (= 28)
             */
            nextBillingTimestamp += billingDay > daysInNextMonth
                ? (daysInMonth - billingDay + daysInNextMonth)
                : daysInMonth;

            break;
        }

        nextBillingTimestamp *= 86_400;
    }

    /**
     * get timestamp of certain date in next month
     */
    function getTimestampOfNextDate(uint256 timestamp, uint8 date)
        public
        pure
        returns (uint256 nextDateTimestamp)
    {
        (
            ,
            uint256 yearStartDay,
            uint256 dayOfYear,
            uint256 yearsFrom1972
        ) = getDaysFromTimestamp(timestamp);

        nextDateTimestamp = yearStartDay;

        uint8[12] memory monthsLengths = [
            31,
            yearsFrom1972 % 4 == 0 ? 29 : 28,
            31,
            30,
            31,
            30,
            31,
            31,
            30,
            31,
            30,
            31
        ];

        for (uint256 index = 0; index < 12; index++) {
            uint256 daysInMonth = monthsLengths[index];

            if (dayOfYear > daysInMonth) {
                nextDateTimestamp += daysInMonth;
                dayOfYear -= daysInMonth;
                continue;
            }

            if (index == 11) {
                nextDateTimestamp += daysInMonth + date - 1;
                break;
            }
            uint256 daysInNextMonth = monthsLengths[index + 1];

            nextDateTimestamp +=
                daysInMonth +
                (date > daysInNextMonth ? daysInNextMonth : date) -
                1;

            break;
        }

        nextDateTimestamp *= 86_400;
    }
}