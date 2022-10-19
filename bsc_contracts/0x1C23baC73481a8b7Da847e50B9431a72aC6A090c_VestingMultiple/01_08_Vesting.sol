//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity ^0.8.0;

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
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
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

contract VestingMultiple is Ownable {

    // Using libraries
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Variables
    uint256 private _totalAllocatedAmount;
    uint256 private _initialTimestamp;

    address[] public investors;

    bool public isInitialized = false;
    
    IERC20 private _erc20Token;

    // Events
    event InvestorsAdded(address[] investors, uint256[] tokenAllocations, address caller);
    event InvestorAdded(address indexed investor, address indexed caller, uint256 allocation);
    event InvestorRemoved(address indexed investor, address indexed caller, uint256 allocation);
    event WithdrawnTokens(address indexed investor, uint256 value);
    event TransferInvestment(address indexed owner, uint256 value);
    event RecoverToken(address indexed token, uint256 indexed amount);

    enum AllocationType { SEED, PRIVATE1, PRIVATE2, PUBLIC, TEAM, ADVISORY, MARKETING_BUDGET, RESERVES_DEV, PARTNERSHIPS, CHARITY_FOUNDATION, UNLOCK, SEED_BONUS }

    struct Investor {
        bool exists;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
        AllocationType allocationType;
    }

    mapping(AllocationType => mapping(address => Investor)) public investorsInfo;

    /// @dev Checks that the contract is initialized.
    modifier initialized() {
        require(isInitialized, "not initialized");
        _;
    }

    /// @dev Checks that the contract is initialized.
    modifier notInitialized() {
        require(!isInitialized, "initialized");
        _;
    }

    modifier onlyInvestor(AllocationType _allocationType) {
        require(investorsInfo[_allocationType][_msgSender()].exists, "Only investors allowed");
        _;
    }

    constructor(address _token) {
        _erc20Token = IERC20(_token);
    }

    function getInitialTimestamp() public view returns (uint256 timestamp) {
        return _initialTimestamp;
    }

    /// @dev Adds investors. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investors The addresses of new investors.
    /// @param _tokenAllocations The amounts of the tokens that belong to each investor.
    function addInvestors(
        address[] calldata _investors,
        uint256[] calldata _tokenAllocations,
        uint256[] calldata _withdrawnTokens,
        uint256[] calldata _allocationTypes
    ) external onlyOwner {
        require(_investors.length == _tokenAllocations.length, "different arrays sizes");
        for (uint256 i = 0; i < _investors.length; i++) {
            _addInvestor(_investors[i], _tokenAllocations[i], _withdrawnTokens[i], _allocationTypes[i]);
        }
        emit InvestorsAdded(_investors, _tokenAllocations, msg.sender);
    }

    function withdrawTokens(AllocationType _allocationType) external onlyInvestor(_allocationType) initialized() {
        Investor storage investor = investorsInfo[_allocationType][_msgSender()];

        uint256 tokensAvailable = withdrawableTokens(_allocationType, _msgSender());

        require(tokensAvailable > 0, "no tokens available for withdrawal");

        investor.withdrawnTokens = investor.withdrawnTokens.add(tokensAvailable);
        _erc20Token.safeTransfer(_msgSender(), tokensAvailable);

        emit WithdrawnTokens(_msgSender(), tokensAvailable);
    }

    /// @dev The starting time of TGE
    /// @param _timestamp The initial timestamp, this timestap should be used for vesting
    function setInitialTimestamp(uint256 _timestamp) external onlyOwner() notInitialized() {
        isInitialized = true;
        _initialTimestamp = _timestamp;
    }

    /// @dev withdrawble tokens for an address
    /// @param _investor whitelisted investor address
    function withdrawableTokens(AllocationType _allocationType, address _investor)
        public
        view
        returns (uint256 tokens)
    {
        Investor storage investor = investorsInfo[_allocationType][_investor];
        uint256 availablePercentage = _calculateAvailablePercentage(investor.allocationType);
        uint256 noOfTokens = _calculatePercentage(investor.tokensAllotment, availablePercentage);
        uint256 tokensAvailable = noOfTokens.sub(investor.withdrawnTokens);

        // console.log("Avaialable Percentage: %s%", availablePercentage.div(1e18));
        // console.log("Withdrawable Tokens: %s", tokensAvailable.div(1e18));

        return tokensAvailable;
    }

    /// @dev Adds investor. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investor The addresses of new investors.
    /// @param _tokensAllotment The amounts of the tokens that belong to each investor.
    /// @param _allocationType The allocation type to each investor.
    function _addInvestor(
        address _investor,
        uint256 _tokensAllotment,
        uint256 _withdrawnTokens,
        uint256 _allocationType
    ) internal onlyOwner {
        require(_investor != address(0), "Invalid address");
        require(_tokensAllotment > 0, "the investor allocation must be more than 0");
        AllocationType allocationType = AllocationType(_allocationType);
        Investor storage investor = investorsInfo[allocationType][_investor];

        require(investor.tokensAllotment == 0, "investor already added");

        investor.tokensAllotment = _tokensAllotment;
        investor.withdrawnTokens = _withdrawnTokens;
        investor.exists = true;
        investors.push(_investor);
        investor.allocationType = allocationType;

        _totalAllocatedAmount = _totalAllocatedAmount.add(_tokensAllotment);
        emit InvestorAdded(_investor, _msgSender(), _tokensAllotment);
    }

    /// @dev Removes investor. This function doesn't limit max gas consumption,
    /// so having too many investors can cause it to reach the out-of-gas error.
    /// @param _investor Investor address.
    function removeInvestor(AllocationType _allocationType, address _investor) external onlyOwner() {
        require(_investor != address(0), "invalid address");
        Investor storage investor = investorsInfo[_allocationType][_investor];
        uint256 allocation = investor.tokensAllotment;
        require(allocation > 0, "the investor doesn't exist");

        _totalAllocatedAmount = _totalAllocatedAmount.sub(allocation);
        investor.exists = false;
        investor.tokensAllotment = 0;

        emit InvestorRemoved(_investor, _msgSender(), allocation);
    }

    /// @dev calculate percentage value from amount
    /// @param _amount amount input to find the percentage
    /// @param _percentage percentage for an amount
    function _calculatePercentage(uint256 _amount, uint256 _percentage) private pure returns (uint256 percentage) {
        return _amount.mul(_percentage).div(100).div(1e18);
    }

    function _calculateAvailablePercentage(AllocationType allocationType)
        private
        view
        returns (uint256 availablePercentage)
    {
        uint256 initialReleasePercentage;
        uint256 remainingDistroPercentage;
        uint256 noOfRemaingDays;
        uint256 initialCliff;
        uint256 vestingDuration;
        uint256 currentTimeStamp = block.timestamp;

        if (allocationType == AllocationType.SEED) {
            // 5% on TGE/0 months cliff/Daily Linear Unlock for 9 months after that (9 months total)
            //amended 0% on TGE
            initialReleasePercentage = uint256(0).mul(1e18);
            initialCliff = _initialTimestamp + 0 days;
            remainingDistroPercentage = 100;
            noOfRemaingDays = 180;
            vestingDuration = _initialTimestamp + 0 days + 180 days;
        } else if (allocationType == AllocationType.PRIVATE1) {
            // 10% on TGE/0 months cliff/Daily Linear Unlock for 6 months after that (6 months total)
            //amended 0% on TGE
            initialReleasePercentage = uint256(0).mul(1e18);
            initialCliff = _initialTimestamp + 0 days;
            remainingDistroPercentage = 100;
            noOfRemaingDays = 90;
            vestingDuration = _initialTimestamp + 0 days + 90 days;
        } else if (allocationType == AllocationType.PRIVATE2) {
            // 10% on TGE/0 months cliff/Daily Linear Unlock for 6 months after that (6 months total)
            //amended 0% on TGE
            initialReleasePercentage = uint256(0).mul(1e18);
            initialCliff = _initialTimestamp + 0 days;
            remainingDistroPercentage = 100;
            noOfRemaingDays = 90;
            vestingDuration = _initialTimestamp + 0 days + 90 days;
        } else if (allocationType == AllocationType.PUBLIC) {
            // 25% on TGE/0 month cliff/Daily linear unlock for 3 months after (3 months total)
            //amended 0% on TGE
            initialReleasePercentage = uint256(0).mul(1e18);
            initialCliff = _initialTimestamp + 0 days;
            remainingDistroPercentage = 100;
            noOfRemaingDays = 90;
            vestingDuration = _initialTimestamp + 0 days + 90 days;





        } else if (allocationType == AllocationType.TEAM) {
            // 0% on TGE/12 months cliff/Daily Linear Unlock for 10 months after that (22 months total)
            initialReleasePercentage = uint256(0).mul(1e18);
            initialCliff = _initialTimestamp + 365 days;
            remainingDistroPercentage = 100;
            noOfRemaingDays = 300;
            vestingDuration = _initialTimestamp + 365 days + 300 days;
        } else if (allocationType == AllocationType.ADVISORY) {
            // 0% on TGE/6 months cliff/Daily Linear Unlock for 10 months after that (16 months total)
            initialReleasePercentage = uint256(0).mul(1e18);
            initialCliff = _initialTimestamp + 180 days;
            remainingDistroPercentage = 100;
            noOfRemaingDays = 300;
            vestingDuration = _initialTimestamp + 180 days + 300 days;
        } else if (allocationType == AllocationType.MARKETING_BUDGET) {
            // 10% on TGE/0 months cliff/Daily Linear Unlock for 9 months after that (9 months total)
            initialReleasePercentage = uint256(10).mul(1e18);
            initialCliff = _initialTimestamp + 0 days;
            remainingDistroPercentage = 90;
            noOfRemaingDays = 270;
            vestingDuration = _initialTimestamp + 0 days + 270 days;
        } else if (allocationType == AllocationType.RESERVES_DEV) {
            // 0% on TGE/3 month cliff/Daily linear unlock for 10 months after (13 months total)
            initialReleasePercentage = uint256(0).mul(1e18);
            initialCliff = _initialTimestamp + 90 days;
            remainingDistroPercentage = 100;
            noOfRemaingDays = 300;
            vestingDuration = _initialTimestamp + 90 days + 300 days;
        } else if (allocationType == AllocationType.PARTNERSHIPS) {
            // 0% on TGE/12 month cliff/Daily linear unlock for 10 months after (22 months total)
            initialReleasePercentage = uint256(0).mul(1e18);
            initialCliff = _initialTimestamp + 365 days;
            remainingDistroPercentage = 100;
            noOfRemaingDays = 300;
            vestingDuration = _initialTimestamp + 365 days + 300 days;
        } else if (allocationType == AllocationType.CHARITY_FOUNDATION) {
            // 0% on TGE/3 month cliff/Daily linear unlock for 10 months after (13 months total)
            initialReleasePercentage = uint256(0).mul(1e18);
            initialCliff = _initialTimestamp + 90 days;
            remainingDistroPercentage = 100;
            noOfRemaingDays = 300;
            vestingDuration = _initialTimestamp + 90 days + 300 days;
        } else if (allocationType == AllocationType.UNLOCK) {
            // 100% on TGE/0 month cliff/Daily linear unlock for 0 months after (0 months total)
            //amended 0% on TGE
            initialReleasePercentage = uint256(0).mul(1e18);
            initialCliff = _initialTimestamp + 0 days;
            remainingDistroPercentage = 100;
            noOfRemaingDays = 0;
            vestingDuration = _initialTimestamp + 0 days + 0 days;

            
        } else if (allocationType == AllocationType.SEED_BONUS) {
            // 0% on TGE/24 month cliff/Daily linear unlock for 12 months after (36 months total)
            initialReleasePercentage = uint256(0).mul(1e18);
            initialCliff = _initialTimestamp + 640 days;
            remainingDistroPercentage = 100;
            noOfRemaingDays = 365;
            vestingDuration = _initialTimestamp + 730 days + 365 days;
        } 

        uint256 everyDayReleasePercentage = remainingDistroPercentage.mul(1e18).div(noOfRemaingDays);

        if (currentTimeStamp > _initialTimestamp) {
            if (currentTimeStamp <= initialCliff) {
                return initialReleasePercentage;
            } else if (currentTimeStamp > initialCliff && currentTimeStamp < vestingDuration) {
                uint256 noOfDays = BokkyPooBahsDateTimeLibrary.diffDays(initialCliff, currentTimeStamp);

                uint256 currentUnlockedPercentage = noOfDays.mul(everyDayReleasePercentage);
                // console.log("Everyday Percentage: %s, Days: %s, Current Unlock %: %s",everyDayReleasePercentage, noOfDays, currentUnlockedPercentage);

                return initialReleasePercentage.add(currentUnlockedPercentage);
            } else {
                return uint256(100).mul(1e18);
            }
        }
    }

    function recoverToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }
}