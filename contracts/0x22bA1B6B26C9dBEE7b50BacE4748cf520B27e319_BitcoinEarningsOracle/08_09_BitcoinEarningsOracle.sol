// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IEarningsOracle.sol";

/**
 * @title Track and simulate bitcoin mining and forecasting reward
 */
contract BitcoinEarningsOracle is IEarningsOracle, AccessControl {
    bytes32 public constant TRACK_ROLE = keccak256("TRACK_ROLE");

    event TrackDailyEarnings(uint256 day, uint256 dailyEarnings);
    event ComplementDailyEarnings(uint256 day, uint256 dailyEarnings);

    using SafeMath for uint256;

    mapping(uint256 => uint256) public _dailyEarnings;

    uint256 private latest_;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addTracker(address tracker) public {
        grantRole(TRACK_ROLE, tracker);
    }

    function rmTracker(address tracker) public {
        revokeRole(TRACK_ROLE, tracker);
    }

    function getRound(uint256 day)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _dailyEarnings[day];
    }

    function lastRound()
        public
        view
        virtual
        override
        returns (uint256, uint256)
    {
        return (latest_, _dailyEarnings[latest_]);
    }

    function _today() private view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function complementDailyEarnings(
        uint256 day_,
        uint256[] memory earnings_,
        uint256[] memory hashrates_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            day_ < _today(),
            "BitcoinYeildOracle: can't to complement on today"
        );
        require(
            _dailyEarnings[day_] == 0,
            "BitcoinYeildOracle: complement only missing earning"
        );
        _makerDailyEarnings(day_, earnings_, hashrates_);
        emit ComplementDailyEarnings(day_, _dailyEarnings[day_]);
    }

    function trackDailyEarnings(
        uint256[] memory earnings_,
        uint256[] memory hashrates_
    ) public onlyRole(TRACK_ROLE) {
        uint256 day = _today();
        _makerDailyEarnings(day, earnings_, hashrates_);
        emit TrackDailyEarnings(day, _dailyEarnings[day]);
    }

    function _makerDailyEarnings(
        uint256 day_,
        uint256[] memory earnings_,
        uint256[] memory hashrates_
    ) private {
        require(
            earnings_.length == hashrates_.length,
            "BitcoinYeildOracle: earnings and hashrates length mismatch"
        );
        uint256 hashrateSum = 0;
        uint256 earnings = 0;
        for (uint256 i = 0; i < hashrates_.length; i++) {
            earnings = earnings.add(earnings_[i].mul(hashrates_[i]));
            hashrateSum = hashrateSum.add(hashrates_[i]);
        }

        earnings = earnings.div(hashrateSum);
        _dailyEarnings[day_] = earnings;
        if (latest_ < day_) {
            latest_ = day_;
        }
    }
}