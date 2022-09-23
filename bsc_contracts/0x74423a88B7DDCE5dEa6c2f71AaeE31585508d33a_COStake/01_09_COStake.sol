// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract COStake is AccessControl, Pausable {
    event StakeUpdate(address indexed from, uint64 balance);
    event WithdrawRequest(address indexed from, uint64 until);
    event ClaimYield(address indexed from, uint64 amount);

    IERC20 private immutable token;

    struct StakeState {
        uint64 balance;
        uint64 lockedUntil; // 0 if withdraw is not requested
        uint64 since;
        uint64 accumulatedYield; // how much unclaimed yield is available to the user
    }
    // denotes a change in yield
    struct YieldPoint {
        uint128 yieldRate; // New yield rate in the format of (1/percentage)*365
        uint128 timestamp; // timestamp of change
    }

    mapping(address => StakeState) private _states;
    YieldPoint[] yieldTimeline; // Records the changes in the yieldrate
    uint public unlockPeriod = 2 weeks;

    address public yieldBank; // wallet which holds yield rewards for users

    constructor(
        IERC20 _token,
        uint128 _initialRate,
        address _yieldBank,
        address _default_admin
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin);
        token = _token;
        yieldTimeline.push(YieldPoint(_initialRate, uint128(block.timestamp)));
        yieldBank = _yieldBank;
    }

    function pauseHandler() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpauseHandler() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setUnlockPeriod(uint _unlockPeriod)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(unlockPeriod < 52 weeks, "Unlock period must be under 1 year");
        unlockPeriod = _unlockPeriod;
    }

    function setYieldBank(address _yieldBank)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        yieldBank = _yieldBank;
    }

    function setYieldRate(uint128 _yieldRate)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_yieldRate > 0, "Yield rate must be greater than 0");
        yieldTimeline.push(YieldPoint(_yieldRate, uint128(block.timestamp)));
    }

    function pauseYield() external onlyRole(DEFAULT_ADMIN_ROLE) {
        setYieldRate(type(uint128).max);
    }

    function getStakeState(address account)
        external
        view
        returns (
            uint64,
            uint64,
            uint64
        )
    {
        StakeState storage ss = _states[account];
        return (ss.balance, ss.lockedUntil, ss.since);
    }

    function calculateAccumulatedYield(StakeState memory ss)
        internal
        view
        returns (uint64)
    {
        uint64 yield = ss.accumulatedYield;
        if (ss.balance > 0) {
            uint256 until = block.timestamp;
            if (ss.lockedUntil > 0 && ss.lockedUntil < block.timestamp) {
                until = ss.lockedUntil;
            }
            uint64 delta;
            if (until > ss.since) {
                if (ss.lockedUntil == 0) {
                    // below calculates the delta in yield since ss.since
                    uint last;
                    YieldPoint memory mostRecentYield = yieldTimeline[
                        yieldTimeline.length - 1
                    ];
                    if (ss.since < mostRecentYield.timestamp) {
                        for (uint i = 0; i < yieldTimeline.length; i++) {
                            // find the earliest applicable yield rate based on ss.since and loop through all the
                            // following yieldTimeline/dates
                            if (yieldTimeline[i].timestamp < ss.since) {
                                continue;
                            } else {
                                YieldPoint memory prevYield = yieldTimeline[
                                    i - 1
                                ];
                                last = prevYield.timestamp < ss.since
                                    ? ss.since
                                    : prevYield.timestamp;
                                delta = uint64(
                                    ((ss.balance *
                                        (yieldTimeline[i].timestamp - last)) /
                                        86400) / prevYield.yieldRate
                                ); // calculate the delta for a specific yield period
                                yield += delta;
                            }
                        }
                    }
                    // finally calculate the delta of latest yield rate up to current date
                    last = mostRecentYield.timestamp < ss.since
                        ? ss.since
                        : mostRecentYield.timestamp;
                    delta = uint64(
                        ((ss.balance * (until - last)) / 86400) /
                            mostRecentYield.yieldRate
                    );
                    yield += delta;
                }
            }
        }
        return (yield);
    }

    function estimateAccumulatedYield(address account)
        public
        view
        returns (uint)
    {
        StakeState storage ss = _states[account];
        return calculateAccumulatedYield(ss);
    }

    function updateAccumulatedYield(StakeState storage ss) private {
        ss.accumulatedYield = calculateAccumulatedYield(ss);
    }

    function stake(uint64 amount) external whenNotPaused {
        StakeState storage ss = _states[msg.sender];
        require(amount > 0, "amount must be positive");
        require(ss.balance <= amount, "cannot decrease balance");
        updateAccumulatedYield(ss);

        uint128 delta = amount - ss.balance;
        if (delta > 0) {
            require(
                token.transferFrom(msg.sender, address(this), delta),
                "transfer unsuccessful"
            );
        }

        ss.balance = amount;
        ss.lockedUntil = 0;
        ss.since = uint64(block.timestamp);

        emit StakeUpdate(msg.sender, amount);
    }

    function requestWithdraw() external {
        StakeState storage ss = _states[msg.sender];
        require(ss.balance > 0);
        updateAccumulatedYield(ss);

        ss.since = uint64(block.timestamp);
        ss.lockedUntil = uint64(block.timestamp + unlockPeriod);

        emit WithdrawRequest(msg.sender, ss.lockedUntil);
    }

    function withdraw() external {
        StakeState storage ss = _states[msg.sender];
        require(ss.balance > 0, "must have tokens to withdraw");
        require(ss.lockedUntil != 0, "unlock not requested");
        require(ss.lockedUntil < block.timestamp, "still locked");
        updateAccumulatedYield(ss);

        uint128 balance = ss.balance;
        ss.balance = 0;
        ss.lockedUntil = 0;
        ss.since = 0;

        require(token.transfer(msg.sender, balance), "transfer unsuccessful");

        emit StakeUpdate(msg.sender, 0);
    }

    function withdrawAndClaimYield() external {
        StakeState storage ss = _states[msg.sender];
        require(ss.balance > 0, "must have tokens to withdraw");
        require(ss.lockedUntil != 0, "unlock not requested");
        require(ss.lockedUntil < block.timestamp, "still locked");
        updateAccumulatedYield(ss);

        uint128 balance = ss.balance;
        ss.balance = 0;
        ss.lockedUntil = 0;
        ss.since = 0;

        uint yield = ss.accumulatedYield;
        ss.accumulatedYield = 0;

        token.transferFrom(yieldBank, msg.sender, yield);
        require(token.transfer(msg.sender, balance), "transfer unsuccessful");

        emit StakeUpdate(msg.sender, 0);
    }

    function claimYield() external {
        StakeState storage ss = _states[msg.sender];
        updateAccumulatedYield(ss);

        ss.since = uint64(block.timestamp);
        uint64 amount = ss.accumulatedYield;
        ss.accumulatedYield = 0;
        token.transferFrom(yieldBank, msg.sender, amount);

        emit ClaimYield(msg.sender, amount);
    }
}