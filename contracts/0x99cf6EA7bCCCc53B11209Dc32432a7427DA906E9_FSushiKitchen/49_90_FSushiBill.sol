// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./base/BaseERC20.sol";
import "./interfaces/IFSushiBill.sol";
import "./interfaces/ISousChef.sol";
import "./interfaces/IFSushiKitchen.sol";
import "./libraries/DateUtils.sol";

contract FSushiBill is BaseERC20, IFSushiBill {
    using SafeERC20 for IERC20;
    using DateUtils for uint256;

    address public override sousChef;
    uint256 public override pid;
    address public override fToken;

    /**
     * @notice points = ∫W(t)dt, where W(t) is the total supply at the week
     */
    mapping(uint256 => uint256) public override points; // week => points
    /**
     * @notice points are guaranteed to be correct before this time's week start
     */
    uint256 public override lastCheckpoint; // timestamp

    /**
     * @notice userPoints = ∫w(t)dt, where a(t) is the balance of account at the week
     */
    mapping(address => mapping(uint256 => uint256)) public override userPoints; // account => week => points
    /**
     * @notice userPoints of account is guaranteed to be correct before this week
     */
    mapping(address => uint256) public override userLastCheckpoint; // account => timestamp
    /**
     * @notice how much rewards were claimed in total for account
     */
    mapping(address => uint256) public override claimedRewards; // account => amount
    /**
     * @notice in the next claim, rewards will be accumulated from this week
     */
    mapping(address => uint256) public override nextClaimableWeek; // account => week

    function initialize(uint256 _pid, address _fToken) external override initializer {
        if (_fToken == address(0)) return;

        BaseERC20_initialize(
            string.concat("Flash Sushi Bill for ", IERC20Metadata(_fToken).name()),
            string.concat("x", IERC20Metadata(_fToken).symbol()),
            "1"
        );

        sousChef = msg.sender;
        pid = _pid;
        fToken = _fToken;
    }

    function deposit(uint256 amount, address beneficiary) external override {
        userCheckpoint(msg.sender);

        if (amount > 0) {
            IERC20(fToken).safeTransferFrom(msg.sender, address(this), amount);

            uint256 balance = _balanceOf[msg.sender] + amount;
            _balanceOf[msg.sender] = balance;
            uint256 totalSupply = _totalSupply + amount;
            _totalSupply = totalSupply;

            _mint(beneficiary, amount);
        }

        emit Deposit(msg.sender, amount, beneficiary);
    }

    function withdraw(uint256 amount, address beneficiary) external override {
        userCheckpoint(msg.sender);

        if (amount > 0) {
            uint256 balance = _balanceOf[msg.sender] - amount;
            _balanceOf[msg.sender] = balance;
            uint256 totalSupply = _totalSupply - amount;
            _totalSupply = totalSupply;

            _burn(msg.sender, amount);

            IERC20(fToken).safeTransfer(beneficiary, amount);
        }

        emit Withdraw(msg.sender, amount, beneficiary);
    }

    /**
     * @dev if this function doesn't get called for 512 weeks (around 9.8 years) this contract breaks
     */
    function checkpoint() public override {
        ISousChef(sousChef).checkpoint();

        uint256 prevCheckpoint = lastCheckpoint;
        _updatePoints(points, _totalSupply, prevCheckpoint);
        if (prevCheckpoint < block.timestamp) {
            lastCheckpoint = block.timestamp;
        }

        emit Checkpoint();
    }

    function userCheckpoint(address account) public override {
        checkpoint();

        uint256 prevCheckpoint = userLastCheckpoint[account];
        _updatePoints(userPoints[account], _balanceOf[account], prevCheckpoint);
        if (prevCheckpoint < block.timestamp) {
            userLastCheckpoint[account] = block.timestamp;
        }

        emit UserCheckpoint(account);
    }

    function _updatePoints(
        mapping(uint256 => uint256) storage _points,
        uint256 balance,
        uint256 lastTime
    ) internal {
        if (balance == 0) return;

        if (lastTime == 0) {
            uint256 startWeek = ISousChef(sousChef).startWeek();
            lastTime = startWeek.toTimestamp();
        }

        uint256 from = lastTime.toWeekNumber();
        for (uint256 i; i < 512; ) {
            uint256 week = from + i;
            uint256 weekStart = week.toTimestamp();
            uint256 weekEnd = weekStart + WEEK;
            if (block.timestamp <= weekStart) break;
            if (block.timestamp < weekEnd) {
                _points[week] += balance * (block.timestamp - Math.max(lastTime, weekStart));
                break;
            }
            if (i == 0) {
                _points[week] += balance * (weekEnd - lastTime);
            } else {
                _points[week] += balance * WEEK;
            }

            unchecked {
                ++i;
            }
        }
    }

    function claimRewards(address beneficiary) external {
        userCheckpoint(msg.sender);

        uint256 from = nextClaimableWeek[msg.sender];
        if (from == block.timestamp.toWeekNumber()) return;
        if (from == 0) {
            from = ISousChef(sousChef).startWeek();
        }

        (address _sousChef, uint256 _pid) = (sousChef, pid);
        address kitchen = ISousChef(_sousChef).kitchen();
        IFSushiKitchen(kitchen).checkpoint(_pid);

        // add week-by-week rewards until the last week
        uint256 totalRewards;
        uint256 to = block.timestamp.toWeekNumber(); // exclusive last index
        for (uint256 i; i < 512; ) {
            uint256 week = from + i;
            if (to <= week) break;
            uint256 weeklyRewards = ISousChef(_sousChef).weeklyRewards(week);
            uint256 weight = IFSushiKitchen(kitchen).relativeWeightAt(_pid, (week + 1).toTimestamp());
            uint256 rewards = points[week] == 0
                ? 0
                : (weeklyRewards * weight * userPoints[msg.sender][week]) / points[week] / 1e18;
            totalRewards += rewards;

            unchecked {
                ++i;
            }
        }
        nextClaimableWeek[msg.sender] = to;

        if (totalRewards > 0) {
            claimedRewards[msg.sender] += totalRewards;

            ISousChef(sousChef).mintFSushi(_pid, beneficiary, totalRewards);

            emit ClaimRewards(msg.sender, beneficiary, totalRewards);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override returns (uint256 balanceOfFrom, uint256 balanceOfTo) {
        userCheckpoint(from);
        userCheckpoint(to);

        return super._transfer(from, to, amount);
    }
}