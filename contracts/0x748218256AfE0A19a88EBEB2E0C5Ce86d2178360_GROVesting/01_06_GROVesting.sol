// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMintable {
    function mint(address _receiver, uint256 _amount) external;
}

interface IHodler {
    function add(uint256 amount) external;
}

struct AccountInfo {
    uint256 total;
    uint256 startTime;
}

interface IVesting {
    function initUnlockedPercent() external view returns (uint256);

    function totalLockedAmount() external view returns (uint256);

    function hodlerClaims() external view returns (address);

    function globalStartTime() external view returns (uint256);

    function accountInfos(address account) external view returns (AccountInfo memory);

    function withdrawals(address account) external view returns (uint256);
}

contract GROVesting is Ownable {
    using SafeERC20 for IERC20;

    uint256 internal constant ONE_YEAR_SECONDS = 31556952; // average year (including leap years) in seconds
    uint256 private constant DEFAULT_MAX_LOCK_PERIOD = ONE_YEAR_SECONDS * 1; // 1 years period
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR = 10000; // BP
    uint256 internal constant TWO_WEEKS = 604800; // two weeks in seconds
    uint256 public lockPeriodFactor = PERCENTAGE_DECIMAL_FACTOR;

    IMintable public distributer;
    // percentage of tokens that are available immediatly when a vesting postiion is created
    uint256 public initUnlockedPercent = 0;
    // percentage of tokens that can be claimed immediatly rather than creating a vesting position
    uint256 public instantUnlockPercent = 3000;
    // Active airdrops and liquidity pools
    mapping(address => bool) public vesters;

    uint256 public totalLockedAmount;
    // vesting actions
    uint256 constant CREATE = 0;
    uint256 constant ADD = 1;
    uint256 constant EXIT = 2;
    uint256 constant EXTEND = 3;

    address public hodlerClaims;

    mapping(address => AccountInfo) public accountInfos;
    mapping(address => uint256) public withdrawals;
    // Start time for the global vesting curve
    uint256 public globalStartTime;

    IVesting public oldVesting;

    mapping(address => bool) public userMigrated;

    bool public paused = true;
    bool public initialized = false;

    address public immutable TIME_LOCK;

    event LogVester(address vester, bool status);
    event LogMaxLockPeriod(uint256 newMaxPeriod);
    event LogNewMigrator(address newMigrator);
    event LogNewDistributer(address newDistributer);
    event LogNewBonusContract(address bonusContract);
    event LogNewInitUnlockedPercent(uint256 initUnlockedPercent);
    event LogNewInstantUnlockedPercent(uint256 instantUnlockPercent);

    event LogVest(address indexed user, uint256 totalLockedAmount, uint256 amount, AccountInfo vesting);
    event LogExit(address indexed user, uint256 totalLockedAmount, uint256 amount, uint256 unlocked, uint256 penalty);
    event LogInstantExit(address indexed user, uint256 mintingAmount, uint256 penalty);
    event LogExtend(address indexed user, uint256 newPeriod, AccountInfo newVesting);
    event LogMigrate(address indexed user, AccountInfo vesting);
    event LogSetStatus(bool pause);

    modifier onlyTimelock() {
        require(msg.sender == TIME_LOCK, "msg.sender != timelock");
        _;
    }

    constructor(IVesting _oldVesting, address timeLock) {
        if (address(_oldVesting) == address(0)) {
            globalStartTime = block.timestamp;
        } else {
            oldVesting = _oldVesting;
            totalLockedAmount = _oldVesting.totalLockedAmount();
            globalStartTime = _oldVesting.globalStartTime();
        }

        TIME_LOCK = timeLock;
    }

    function setInitUnlockedPercent(uint256 _initUnlockedPercent) external onlyOwner {
        require(
            instantUnlockPercent <= PERCENTAGE_DECIMAL_FACTOR,
            "setInstantUnlockedPercent: _instantUnlockPercent > 100%"
        );
        initUnlockedPercent = _initUnlockedPercent;
        emit LogNewInstantUnlockedPercent(_initUnlockedPercent);
    }

    function setInstantUnlockedPercent(uint256 _instantUnlockPercent) external onlyOwner {
        require(
            instantUnlockPercent <= PERCENTAGE_DECIMAL_FACTOR,
            "setInstantUnlockedPercent: _instantUnlockPercent > 100%"
        );
        instantUnlockPercent = _instantUnlockPercent;
        emit LogNewInstantUnlockedPercent(instantUnlockPercent);
    }

    function setDistributer(address _distributer) external onlyOwner {
        distributer = IMintable(_distributer);
        emit LogNewDistributer(_distributer);
    }

    function setStatus(bool pause) external onlyTimelock {
        paused = pause;
        emit LogSetStatus(pause);
    }

    function initialize() external onlyOwner {
        require(initialized == false, "initialized: Contract already initialized");
        paused = false;
        initialized = true;
        emit LogSetStatus(false);
    }

    // @notice Estimation for how much groove is in the vesting contract
    // @dev Total groove is estimated by multiplying the total gro amount with the % amount has vested
    //  according to the global vesting curve. As time passes, there will be less global groove, as
    //  each individual users position will vest. The vesting can be estimated by continiously shifting,
    //  The global vesting curves start date (and end date by extension), which gets updated whenever user
    //  interacts with the vesting contract ( see updateGlobalTime )
    function totalGroove() external view returns (uint256) {
        uint256 _maxLock = maxLockPeriod();
        uint256 _globalEndTime = (globalStartTime + _maxLock);
        uint256 _now = block.timestamp;
        if (_now >= _globalEndTime) {
            return 0;
        }

        uint256 total = totalLockedAmount;

        return
            ((total * ((PERCENTAGE_DECIMAL_FACTOR - initUnlockedPercent) * (_globalEndTime - _now))) / _maxLock) /
            PERCENTAGE_DECIMAL_FACTOR;
    }

    // @notice Calculate the start point of the global vesting curve
    // @param amount gro token amount
    // @param startTime users position startTime
    // @param newStartTime users new startime if applicable, 0 otherwise.
    // @param action user interaction with the vesting contract : 0) create/add position 1) exit position 2) extend position
    // @dev The global vesting curve is an estimation to the amount of groove in the contract. The curve dictates a linear decline
    //  of the amount of groove in the contract. As users interact with the contract the start date of the curve gets adjusted to
    //  capture changes in individual users vesting position at that specific point in time. depending on the type of interaction
    //  the user takes, the new curve will be defined as:
    //      Create position:
    //          g_st = g_st * (g_amt - u_amt) / (g_amt) + (u_st * u_amt) / (g_amt)
    //
    //      Add to position:
    //          (g_st * g_amt - u_old_st * u_tot + u_new_st * (u_tot + u_amt)) / (g_amt + u_amt)
    //
    //      Exit position:
    //          g_st = g_st + (g_st - u_st) * u_amt / (g_amt)
    //
    //      Extend position:
    //          g_st = g_st + (u_tot * u_st) / (g_amt)
    //
    //      Where:
    //          g_st : global vesting curve start time
    //          u_st : user start time
    //          g_amt : global gro amount
    //          u_amt : user gro amount added
    //          u_tot : user current gro amount
    //
    //  Special care needs to be taken as positions that dont exit will cause this to drift, when a user with an position that
    //  has 'overvested' takes an action, this needs to be accounted for. Unaccounted for drift (users that dont interact with the contract
    //  after their vesting period has expired) will have to be dealt with offchain.
    function updateGlobalTime(
        uint256 amount,
        uint256 startTime,
        uint256 userTotal,
        uint256 newStartTime,
        uint256 action
    ) internal {
        uint256 _totalLockedAmount = totalLockedAmount;
        if (action == CREATE) {
            // When creating a position we need to add the new amount to the global total
            _totalLockedAmount = _totalLockedAmount + amount;
        } else if (action == EXIT) {
            // When exiting we remove from the global total
            _totalLockedAmount = _totalLockedAmount - amount;
        } else if (_totalLockedAmount == userTotal) {
            globalStartTime = startTime;
            return;
        }
        uint256 _globalStartTime = globalStartTime;

        if (_totalLockedAmount == 0) {
            return;
        }

        if (action == ADD) {
            // adding to an existing position
            // formula for calculating add to position, including dealing with any drift caused by over vesting:
            //      (g_st * g_amt - u_old_st * u_tot + u_new_st * (u_tot + u_amt)) / (g_amt + u_amt)
            // this removes the impact of the users old position, and adds in the
            //  new position (user old amount + user added amount) based on the new start date.
            uint256 newWeightedTimeSum = (_globalStartTime * _totalLockedAmount + newStartTime * (userTotal + amount)) -
                startTime *
                userTotal;
            globalStartTime = newWeightedTimeSum / (_totalLockedAmount + amount);
        } else if (action == EXIT) {
            // exiting an existing position
            // note that g_amt = prev_g_amt - u_amt
            // g_st = g_st + (g_st - u_st) * u_amt / (g_amt)
            globalStartTime = uint256(
                int256(_globalStartTime) +
                    ((int256(_globalStartTime) - int256(startTime)) * int256(amount)) /
                    int256(_totalLockedAmount)
            );
        } else if (action == EXTEND) {
            // extending an existing position
            // g_st = g_st + (u_tot * (u_new_st - u_st)) / (g_amt)
            globalStartTime = _globalStartTime + (userTotal * (newStartTime - startTime)) / _totalLockedAmount;
        } else {
            // Createing new vesting positions
            // note that g_amt = prev_g_amt + u_amt
            // g_st = g_st + (g_amt - u_amt) / (g_amt) + (u_st * u_amt) / (g_amt)
            globalStartTime =
                (_globalStartTime * (_totalLockedAmount - amount)) /
                _totalLockedAmount +
                (startTime * amount) /
                _totalLockedAmount;
        }
    }

    /// @notice Set the vesting bonus contract
    /// @param _hodlerClaims Address of vesting bonus contract
    function setHodlerClaims(address _hodlerClaims) external onlyOwner {
        hodlerClaims = _hodlerClaims;
        emit LogNewBonusContract(_hodlerClaims);
    }

    /// @notice Get the current max lock period - dictates the end date of users vests
    function maxLockPeriod() public view returns (uint256) {
        return (DEFAULT_MAX_LOCK_PERIOD * lockPeriodFactor) / PERCENTAGE_DECIMAL_FACTOR;
    }

    // Adds a new contract that can create vesting positions
    function setVester(address vester, bool status) public onlyOwner {
        vesters[vester] = status;
        emit LogVester(vester, status);
    }

    /// @notice Sets amount of time the vesting lasts
    /// @param maxPeriodFactor Factor to apply to the vesting period
    function setMaxLockPeriod(uint256 maxPeriodFactor) external onlyOwner {
        // cant extend the vesting period more than 200%
        require(maxPeriodFactor <= 20000, "adjustLockPeriod: newFactor > 20000");
        // max Lock period needs to be longer than a month
        require(
            (maxPeriodFactor * DEFAULT_MAX_LOCK_PERIOD) / PERCENTAGE_DECIMAL_FACTOR > TWO_WEEKS * 2,
            "adjustLockPeriod: newFactor to small"
        );
        lockPeriodFactor = maxPeriodFactor;
        emit LogMaxLockPeriod(maxLockPeriod());
    }

    /// @notice Create or modify a vesting position
    /// @param vest Add/Create vesting position (true), or claim it immediatly (false)
    /// @param account Account which to add vesting position for
    /// @param amount Amount to add to vesting position
    function vest(
        bool vest,
        address account,
        uint256 amount
    ) external {
        require(!paused, "vest: paused");

        require(vesters[msg.sender], "vest: !vester");
        require(account != address(0), "vest: !account");
        require(amount > 0, "vest: !amount");
        if (!vest) {
            _instantExit(account, amount);
            return;
        }

        (AccountInfo memory ai, bool fromOld) = getAccountInfo(account);
        uint256 _maxLock = maxLockPeriod();

        if (ai.startTime == 0) {
            // If no position exists, create a new one
            ai.startTime = block.timestamp;
            updateGlobalTime(amount, ai.startTime, 0, 0, CREATE);
        } else {
            // If a position exists, update user's startdate by weighting current time based on GRO being added
            uint256 newStartTime = (ai.startTime * ai.total + block.timestamp * amount) / (ai.total + amount);
            if (newStartTime + _maxLock <= block.timestamp) {
                newStartTime = block.timestamp - (_maxLock) + TWO_WEEKS;
            }
            updateGlobalTime(amount, ai.startTime, ai.total, newStartTime, ADD);
            ai.startTime = newStartTime;
        }

        // update user position
        ai.total += amount;
        accountInfos[account] = ai;
        if (fromOld) {
            userMigrated[account] = true;
        }
        totalLockedAmount += amount;

        emit LogVest(account, totalLockedAmount, amount, ai);
    }

    /// @notice Extend vesting period
    /// @param extension extension to current vesting period
    function extend(uint256 extension) external {
        require(!paused, "extend: paused");

        require(extension <= PERCENTAGE_DECIMAL_FACTOR, "extend: extension > 100%");
        (AccountInfo memory ai, bool fromOld) = getAccountInfo(msg.sender);

        // check if user has a position before extending
        uint256 total = ai.total;
        require(total > 0, "extend: no vesting");

        uint256 _maxLock = maxLockPeriod();
        uint256 startTime = ai.startTime;
        uint256 newPeriod;
        uint256 newStartTime;

        // if the position is over vested, set the extension by moving the start time back from the current
        //  block by (max lock time) - (desired extension).
        if (startTime + _maxLock < block.timestamp) {
            newPeriod = _maxLock - ((_maxLock * extension) / PERCENTAGE_DECIMAL_FACTOR);
            newStartTime = block.timestamp - newPeriod;
        } else {
            newPeriod = (_maxLock * extension) / PERCENTAGE_DECIMAL_FACTOR;
            // Cannot extend pass max lock period, just set startTime to current block
            if (startTime + newPeriod >= block.timestamp) {
                newStartTime = block.timestamp;
            } else {
                newStartTime = startTime + newPeriod;
            }
        }

        accountInfos[msg.sender].startTime = newStartTime;
        if (fromOld) {
            userMigrated[msg.sender] = true;
            accountInfos[msg.sender].total = total;
        }
        // Calculate the difference between the original start time and the new
        updateGlobalTime(0, startTime, total, newStartTime, EXTEND);

        emit LogExtend(msg.sender, newStartTime, ai);
    }

    /// @notice Lets user exit with a fraction of their claim immediatly
    ///     without starting/or adding to an existing vesting position
    /// @param user Address of user that makes claim
    /// @param amount Amount that is claimed
    function _instantExit(address user, uint256 amount) private {
        uint256 mintingAmount = (amount * instantUnlockPercent) / PERCENTAGE_DECIMAL_FACTOR;
        uint256 penalty = amount - mintingAmount;

        // record account total withdrawal
        withdrawals[user] = getWithdrawal(user) + mintingAmount;

        IHodler(hodlerClaims).add(penalty);

        distributer.mint(user, mintingAmount);

        emit LogInstantExit(user, mintingAmount, penalty);
    }

    /// @notice Claim vested tokens, transfering any unclaimed to the hodler pool
    /// @param amount Withdrawal amount use total position if it is greater than total position
    function exit(uint256 amount) external {
        require(!paused, "exit: paused");

        require(amount > 0, "exit: !amount");
        (uint256 total, uint256 unlocked, uint256 startTime, , bool fromOld) = unlockedBalance(msg.sender);
        require(total > 0, "exit: no vesting");
        if (amount >= total) {
            amount = total;
            delete accountInfos[msg.sender];
            if (fromOld) {
                userMigrated[msg.sender] = true;
            }
        } else {
            unlocked = (unlocked * amount) / total;
            accountInfos[msg.sender].total = total - amount;
            if (fromOld) {
                userMigrated[msg.sender] = true;
                accountInfos[msg.sender].startTime = startTime;
            }
        }
        uint256 penalty = amount - unlocked;

        // record account total withdrawal
        withdrawals[msg.sender] = getWithdrawal(msg.sender) + unlocked;
        updateGlobalTime(amount, startTime, 0, 0, EXIT);
        totalLockedAmount -= amount;

        if (penalty > 0) {
            IHodler(hodlerClaims).add(penalty);
        }
        distributer.mint(msg.sender, unlocked);

        emit LogExit(msg.sender, totalLockedAmount, amount, unlocked, penalty);
    }

    /// @notice See the amount of vested assets the account has accumulated
    /// @param account Account to get vested amount for
    function unlockedBalance(address account)
        private
        view
        returns (
            uint256 total,
            uint256 unlocked,
            uint256 startTime,
            uint256 _endTime,
            bool fromOld
        )
    {
        (AccountInfo memory ai, bool old) = getAccountInfo(account);
        fromOld = old;
        startTime = ai.startTime;
        total = ai.total;
        if (startTime > 0) {
            _endTime = startTime + maxLockPeriod();
            if (_endTime > block.timestamp) {
                unlocked = (total * initUnlockedPercent) / PERCENTAGE_DECIMAL_FACTOR;
                unlocked = unlocked + ((total - unlocked) * (block.timestamp - startTime)) / (_endTime - startTime);
            } else {
                unlocked = ai.total;
            }
        }
    }

    /// @notice Get total size of position, vested + vesting
    /// @param account Target account
    function totalBalance(address account) public view returns (uint256 unvested) {
        (AccountInfo memory ai, ) = getAccountInfo(account);
        unvested = ai.total;
    }

    /// @notice Get current unlocked (vested) amount
    /// @param account Target account
    function vestedBalance(address account) external view returns (uint256 unvested) {
        (, uint256 unlocked, , , ) = unlockedBalance(account);
        return unlocked;
    }

    /// @notice Get the current locked (vesting amount
    /// @param account Target account
    function vestingBalance(address account) external view returns (uint256) {
        (uint256 total, uint256 unlocked, , , ) = unlockedBalance(account);
        return total - unlocked;
    }

    /// @notice Get total amount of gro minted to user
    /// @param account Target account
    /// @dev As users can exit and create new vesting positions, this will
    ///     tell the user how much gro they've accrued over all.
    function totalWithdrawn(address account) external view returns (uint256) {
        return getWithdrawal(account);
    }

    /// @notice Get the start and end date for a vesting position
    /// @param account Target account
    /// @dev userfull for showing the amount of time you've got left
    function getVestingDates(address account) external view returns (uint256, uint256) {
        (AccountInfo memory ai, ) = getAccountInfo(account);
        uint256 _startDate = ai.startTime;
        require(_startDate > 0, "getVestingDates: No active position");
        uint256 _endDate = _startDate + maxLockPeriod();

        return (_startDate, _endDate);
    }

    function calcPartialExit(address account, uint256 amount) external view returns (uint256, uint256) {
        (uint256 total, uint256 unlocked, , , ) = unlockedBalance(account);
        if (amount >= total) {
            amount = total;
        } else {
            unlocked = (unlocked * amount) / total;
        }
        return (unlocked, amount - unlocked);
    }

    function getAccountInfo(address account) private view returns (AccountInfo memory ai, bool fromOld) {
        ai = accountInfos[account];
        if (ai.startTime == 0 && address(oldVesting) != address(0) && !userMigrated[account]) {
            ai = oldVesting.accountInfos(account);
            fromOld = true;
        }
    }

    function getWithdrawal(address account) private view returns (uint256 withdrawal) {
        withdrawal = withdrawals[account];
        if (withdrawal == 0 && address(oldVesting) != address(0)) {
            withdrawal = oldVesting.withdrawals(account);
        }
    }
}