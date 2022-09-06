// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./common/IBaseReward.sol";

// Reference @openzeppelin/contracts/token/ERC20/IERC20.sol
interface ILendFlareVotingEscrow {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

contract LendFlareVotingEscrowV2 is Initializable, ReentrancyGuard, ILendFlareVotingEscrow {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 constant WEEK = 1 weeks; // all future times are rounded by week
    uint256 constant MAXTIME = 4 * 365 * 86400; // 4 years
    string constant NAME = "Vote-escrowed LFT";
    string constant SYMBOL = "VeLFT";
    uint8 constant DECIMALS = 18;

    address public token;
    address public rewardManager;

    uint256 public lockedSupply;

    enum DepositTypes {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    struct Point {
        int256 bias;
        int256 slope; // dweight / dt
        uint256 timestamp; // timestamp
    }

    struct LockedBalance {
        uint256 amount;
        uint256 end;
    }

    IBaseReward[] public rewardPools;

    mapping(address => LockedBalance) public lockedBalances;
    mapping(address => mapping(uint256 => Point)) public userPointHistory; // user => ( user epoch => point )
    mapping(address => uint256) public userPointEpoch; // user => user epoch

    bool public expired;
    uint256 public epoch;

    mapping(uint256 => Point) public pointHistory; // epoch -> unsigned point.
    mapping(uint256 => int256) public slopeChanges; // time -> signed slope change

    event Deposit(address indexed provider, uint256 value, uint256 indexed locktime, DepositTypes depositTypes, uint256 ts);
    event Withdraw(address indexed provider, uint256 value, uint256 timestamp);
    event TotalSupply(uint256 prevSupply, uint256 supply);

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() public initializer {}

    function initialize(address _token, address _rewardManager) public initializer {
        token = _token;
        rewardManager = _rewardManager;
    }

    modifier onlyRewardManager() {
        require(rewardManager == msg.sender, "LendFlareVotingEscrow: caller is not the rewardManager");
        _;
    }

    function rewardPoolsLength() external view returns (uint256) {
        return rewardPools.length;
    }

    function addRewardPool(address _v) external onlyRewardManager returns (bool) {
        require(_v != address(0), "!_v");

        rewardPools.push(IBaseReward(_v));

        return true;
    }

    function clearRewardPools() external onlyRewardManager {
        delete rewardPools;
    }

    function _checkpoint(
        address _sender,
        LockedBalance memory _oldLocked,
        LockedBalance memory _newLocked
    ) internal {
        Point memory userOldPoint;
        Point memory userNewPoint;

        int256 oldSlope = 0;
        int256 newSlope = 0;

        if (_sender != address(0)) {
            if (_oldLocked.end > block.timestamp && _oldLocked.amount > 0) {
                userOldPoint.slope = int256(_oldLocked.amount / MAXTIME);
                userOldPoint.bias = userOldPoint.slope * int256(_oldLocked.end - block.timestamp);
            }

            if (_newLocked.end > block.timestamp && _newLocked.amount > 0) {
                userNewPoint.slope = int256(_newLocked.amount / MAXTIME);
                userNewPoint.bias = userNewPoint.slope * int256(_newLocked.end - block.timestamp);
            }

            oldSlope = slopeChanges[_oldLocked.end];

            if (_newLocked.end != 0) {
                if (_newLocked.end == _oldLocked.end) {
                    newSlope = oldSlope;
                } else {
                    newSlope = slopeChanges[_newLocked.end];
                }
            }
        }

        Point memory lastPoint = Point({ bias: 0, slope: 0, timestamp: block.timestamp });

        if (epoch > 0) {
            lastPoint = pointHistory[epoch];
        }

        uint256 lastCheckpoint = lastPoint.timestamp;
        uint256 iterativeTime = _floorToWeek(lastCheckpoint);

        for (uint256 i; i < 255; i++) {
            int256 slope = 0;

            iterativeTime += WEEK;

            if (iterativeTime > block.timestamp) {
                iterativeTime = block.timestamp;
            } else {
                slope = slopeChanges[iterativeTime];
            }

            lastPoint.bias -= lastPoint.slope * int256(iterativeTime - lastCheckpoint);
            lastPoint.slope += slope;

            if (lastPoint.bias < 0) {
                lastPoint.bias = 0; // This can happen
            }

            if (lastPoint.slope < 0) {
                lastPoint.slope = 0; // This cannot happen - just in case
            }

            lastCheckpoint = iterativeTime;
            lastPoint.timestamp = iterativeTime;

            epoch++;

            if (iterativeTime == block.timestamp) {
                break;
            } else {
                pointHistory[epoch] = lastPoint;
            }
        }

        if (_sender != address(0)) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            lastPoint.slope += userNewPoint.slope - userOldPoint.slope;
            lastPoint.bias += userNewPoint.bias - userOldPoint.bias;

            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }

        pointHistory[epoch] = lastPoint;

        if (_sender != address(0)) {
            if (_oldLocked.end > block.timestamp) {
                oldSlope += userOldPoint.slope;

                if (_newLocked.end == _oldLocked.end) {
                    oldSlope -= userNewPoint.slope; // It was a new deposit, not extension
                }

                slopeChanges[_oldLocked.end] = oldSlope;
            }

            if (_newLocked.end > block.timestamp) {
                if (_newLocked.end > _oldLocked.end) {
                    newSlope -= userNewPoint.slope; // old slope disappeared at this point
                    slopeChanges[_newLocked.end] = newSlope;
                }
            }

            uint256 userEpoch = userPointEpoch[_sender] + 1;

            userPointEpoch[_sender] = userEpoch;
            userNewPoint.timestamp = block.timestamp;
            userPointHistory[_sender][userEpoch] = userNewPoint;
        }
    }

    function _depositFor(
        address _sender,
        uint256 _amount,
        uint256 _unlockTime,
        LockedBalance storage _locked,
        DepositTypes _depositTypes
    ) internal {
        uint256 oldLockedSupply = lockedSupply;

        if (_amount > 0) {
            IERC20(token).safeTransferFrom(_sender, address(this), _amount);
        }

        LockedBalance memory oldLocked;

        (oldLocked.amount, oldLocked.end) = (_locked.amount, _locked.end);

        _locked.amount = _locked.amount + _amount;
        lockedSupply = lockedSupply + _amount;

        if (_unlockTime > 0) {
            _locked.end = _unlockTime;
        }

        for (uint256 i = 0; i < rewardPools.length; i++) {
            rewardPools[i].stake(_sender);
        }

        _checkpoint(_sender, oldLocked, _locked);

        emit Deposit(_sender, _amount, _locked.end, _depositTypes, block.timestamp);
        emit TotalSupply(oldLockedSupply, lockedSupply);
    }

    function deposit(uint256 _amount) external nonReentrant {
        LockedBalance storage locked = lockedBalances[msg.sender];

        require(_amount > 0, "need non-zero value");
        require(locked.amount > 0, "no existing lock found");
        require(locked.end > block.timestamp, "cannot add to expired lock. Withdraw");

        _depositFor(msg.sender, _amount, 0, locked, DepositTypes.DEPOSIT_FOR_TYPE);
    }

    function createLock(uint256 _amount, uint256 _unlockTime) public nonReentrant {
        _unlockTime = _floorToWeek(_unlockTime);

        require(_amount > 0, "Must stake non zero amount");
        require(_unlockTime > block.timestamp, "Can only lock until time in the future");

        LockedBalance storage locked = lockedBalances[msg.sender];

        require(locked.amount == 0, "Withdraw old tokens first");

        uint256 roundedMin = _floorToWeek(block.timestamp) + WEEK;
        uint256 roundedMax = _floorToWeek(block.timestamp) + MAXTIME;

        if (_unlockTime < roundedMin) {
            _unlockTime = roundedMin;
        } else if (_unlockTime > roundedMax) {
            _unlockTime = roundedMax;
        }

        _depositFor(msg.sender, _amount, _unlockTime, locked, DepositTypes.CREATE_LOCK_TYPE);
    }

    function increaseAmount(uint256 _amount) external nonReentrant {
        LockedBalance storage locked = lockedBalances[msg.sender];

        require(_amount > 0, "Must stake non zero amount");
        require(locked.amount > 0, "No existing lock found");
        require(locked.end >= block.timestamp, "Can't add to expired lock. Withdraw old tokens first");

        _depositFor(msg.sender, _amount, 0, locked, DepositTypes.INCREASE_LOCK_AMOUNT);
    }

    function increaseUnlockTime(uint256 _unlockTime) external nonReentrant {
        LockedBalance storage locked = lockedBalances[msg.sender];

        _unlockTime = _floorToWeek(_unlockTime);

        require(locked.amount != 0, "No existing lock found");
        require(locked.end > block.timestamp, "Lock expired. Withdraw old tokens first");
        require(_unlockTime <= _floorToWeek(block.timestamp) + MAXTIME, "Can't lock for more than max time");
        require(_unlockTime > locked.end, "Can only increase lock duration");

        _depositFor(msg.sender, 0, _unlockTime, locked, DepositTypes.INCREASE_UNLOCK_TIME);
    }

    function withdraw() public nonReentrant {
        LockedBalance storage locked = lockedBalances[msg.sender];
        LockedBalance memory oldLocked = locked;

        require(block.timestamp >= locked.end, "The lock didn't expire");

        uint256 oldLockedSupply = lockedSupply;
        uint256 lockedAmount = locked.amount;

        lockedSupply = lockedSupply - lockedAmount;

        locked.amount = 0;
        locked.end = 0;

        _checkpoint(msg.sender, oldLocked, locked);

        IERC20(token).safeTransfer(msg.sender, lockedAmount);

        for (uint256 i = 0; i < rewardPools.length; i++) {
            rewardPools[i].withdraw(msg.sender);
        }

        emit Withdraw(msg.sender, lockedAmount, block.timestamp);
        emit TotalSupply(oldLockedSupply, lockedSupply);
    }

    function _floorToWeek(uint256 _t) internal pure returns (uint256) {
        return (_t / WEEK) * WEEK;
    }

    function balanceOf(address _sender) external view override returns (uint256) {
        uint256 t = block.timestamp;
        uint256 userEpoch = userPointEpoch[_sender];

        if (userEpoch == 0) return 0;

        Point storage point = userPointHistory[_sender][userEpoch];

        int256 bias = point.slope * int256(t - point.timestamp);

        if (bias > point.bias) return 0;

        return uint256(point.bias - bias);
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function supplyAt(Point memory _point, uint256 _t) internal view returns (uint256) {
        uint256 iterativeTime = _floorToWeek(_point.timestamp);

        for (uint256 i; i < 255; i++) {
            int256 slope = 0;

            iterativeTime += WEEK;

            if (iterativeTime > _t) {
                iterativeTime = _t;
            } else {
                slope = slopeChanges[iterativeTime];
            }
            _point.bias -= _point.slope * int256(iterativeTime - _point.timestamp);

            if (iterativeTime == _t) {
                break;
            }
            _point.slope += slope;
            _point.timestamp = iterativeTime;
        }

        if (_point.bias < 0) {
            _point.bias = 0;
        }

        return uint256(_point.bias);
    }

    function totalSupply() public view override returns (uint256) {
        return supplyAt(pointHistory[epoch], block.timestamp);
    }
}