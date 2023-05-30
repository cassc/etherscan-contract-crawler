//SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DAOVesting is Initializable, OwnableUpgradeable, ReentrancyGuard {
    using SafeCast for uint;
    using SafeERC20 for IERC20;

    address private constant BURN_ADDRESS = address(0xdead);
    uint16 private constant HUNDRED_PERCENT = 1e3;
    uint16 private constant MIN_BURN_RATE = 5e2;
    uint16 private constant MAX_VESTING_SCHEDULE_STATES = 100;

    /**
        @dev Each user has vesting schedule stored individually. 
        @dev The user vesting schedule changes if either the global vesting schedule changes, 
            the user claims with extra amount or the owner burned his tokens.
        @dev The total duration of the vesting is the same for every user.
     */
    struct User {
        uint128 totalTokens;
        uint128 totalClaimedFromUnlocked;

        uint128 firstUnlockTokens; 
        uint32 linearVestingOffset;
        uint32 linearVestingPeriod;
        uint32 linearUnlocksCount;
        uint32 vestingScheduleUpdatedIndex;

        uint128 totalExtraClaimed;
        uint128 totalFee;
    }
    mapping (address => User) public users;

    /**
        @dev Represents a vesting schedule state. Each vesting schedule change creates a new vesting schedule state.
        @dev The last (and actual) vesting schedule state is stored in the last element of the array.
     */
    struct VestingScheduleState {
        uint32 timestamp;
        uint32 linearVestingOffset;
        uint32 linearVestingPeriod;
        uint32 linearUnlocksCount;
    }
    VestingScheduleState[] public vestingScheduleStates;

    string public roundName;
    address public feeCollector1;
    address public feeCollector2;
    IERC20 public vestingToken;
    uint32 public startTime;
    uint16 public feeSplitPercentage;
    uint16 public firstUnlockPercentage;

    uint128 public totalTokens;
    uint128 public totalClaimed;
    uint128 public totalFee;
    uint128 public totalBurned;

    uint16 public feeRateStart;
    uint16 public feeRateEnd;
    bool public whitelistingAllowed;

    event FeeRateChanged(uint feeRateStart, uint feeRateEnd);
    event VestingScheduleProlongation(uint linearVestingPeriod, uint linearUnlocksCount);
    event LinearVestingOffsetProlongation(uint linearVestingOffset);
    event Whitelist(address userAddress, uint totalTokens);
    event BurnUserTokens(address userAddress, uint amount);
    event Claim(address userAddress, uint baseClaimAmount, uint extraClaimAmount, uint fee);

    function init(
        IERC20 _vestingToken,
        uint32 _startTime,
        uint16 _firstUnlockPercentage,
        uint32 _linearVestingOffset,
        uint32 _linearVestingPeriod,
        uint32 _linearUnlocksCount,
        uint16 _feeRateStart,
        uint16 _feeRateEnd,
        uint16 _feeSplitPercentage,
        address[] memory _feeCollectors,
        string memory _roundName
    ) external initializer {
        __Ownable_init();
        
        require(address(_vestingToken) != address(0));
        require(_firstUnlockPercentage <= HUNDRED_PERCENT);
        require(_feeRateStart >= MIN_BURN_RATE && _feeRateStart <= HUNDRED_PERCENT);
        require(_feeRateEnd >= MIN_BURN_RATE && _feeRateEnd <= _feeRateStart);
        require(_feeSplitPercentage <= HUNDRED_PERCENT);
        require(_feeCollectors[0] != address(0));
        require(_feeCollectors[1] != address(0));

        vestingToken = _vestingToken;
        startTime = _startTime;
        firstUnlockPercentage = _firstUnlockPercentage;
        feeRateStart = _feeRateStart;
        feeRateEnd = _feeRateEnd;
        feeCollector1 = _feeCollectors[0];
        feeCollector2 = _feeCollectors[1];
        feeSplitPercentage = _feeSplitPercentage;
        roundName = _roundName;

        vestingScheduleStates.push(VestingScheduleState(
            startTime,
            _linearVestingOffset,
            _linearVestingPeriod,
            _linearUnlocksCount
        ));

        whitelistingAllowed = true;
    }
    
    // =================== OWNER FUNCTIONS  =================== //

    function setFeeRate(uint16 _feeRateStart, uint16 _feeRateEnd) external onlyOwner {
        require(_feeRateStart >= MIN_BURN_RATE && _feeRateStart <= HUNDRED_PERCENT);
        require(_feeRateEnd >= MIN_BURN_RATE && _feeRateEnd <= _feeRateStart);

        feeRateStart = _feeRateStart;
        feeRateEnd = _feeRateEnd;
        emit FeeRateChanged(_feeRateStart, _feeRateEnd);
    }

    /**
        Sets a new linear vesting period and linear unlocks count. It must not result in shortening the vesting schedule.
        @dev Each change creates a new vesting schedule state (max 100).
     */
    function prolongVestingSchedule(uint32 _linearVestingPeriod, uint32 _linearUnlocksCount) external onlyOwner {
        uint linearUnlocksPassed = _getLinearUnlocksPassed(users[address(0)], 0);
        uint linearUnlocksCountCurrent = getLinearUnlocksCount();
        uint linearVestingPeriodCurrent = getLinearVestingPeriod();

        require(block.timestamp > startTime, "vesting hasn't started");
        require(linearUnlocksPassed < linearUnlocksCountCurrent, "vesting has ended");
        require(vestingScheduleStates.length < MAX_VESTING_SCHEDULE_STATES, "too many states");

        vestingScheduleStates.push(VestingScheduleState(
            block.timestamp.toUint32(),
            (getLinearVestingOffset() + linearVestingPeriodCurrent * linearUnlocksPassed).toUint32(),
            _linearVestingPeriod,
            _linearUnlocksCount
        ));
        _validateVestingSchedule();

        emit VestingScheduleProlongation(_linearVestingPeriod, _linearUnlocksCount);
    }

    /**
        Sets a new linear vesting offset that must not result in shortening the vesting schedule.
        @dev Each change creates a new vesting schedule state (max 100).
     */
    function prolongLinearVestingOffset(uint32 _linearVestingOffset) external onlyOwner {
        uint linearUnlocksPassed = _getLinearUnlocksPassed(users[address(0)], 0);
        uint linearUnlocksCountCurrent = getLinearUnlocksCount();

        require(block.timestamp > startTime, "vesting hasn't started");
        require(linearUnlocksPassed < linearUnlocksCountCurrent, "vesting has ended");
        require(vestingScheduleStates.length < MAX_VESTING_SCHEDULE_STATES, "too many states");

        vestingScheduleStates.push(VestingScheduleState(
            block.timestamp.toUint32(),
            _linearVestingOffset,
            getLinearVestingPeriod().toUint32(),
            (linearUnlocksCountCurrent - linearUnlocksPassed).toUint32() 
        ));
        _validateVestingSchedule();

        emit LinearVestingOffsetProlongation(_linearVestingOffset);
    }

    /**
        Initializes users total tokens and vesting schedules.
     */
    function whitelist(
        address[] calldata userAddresses,
        uint128[] calldata userTotalTokens,
        bool last
    ) external onlyOwner {
        require(whitelistingAllowed, "whitelisting no longer allowed");
        require(userAddresses.length != 0, "0 length array");
        require(userAddresses.length == userTotalTokens.length, "different array lengths");

        uint128 _totalTokens;
        for (uint i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            User storage user = users[userAddress];
            require(userAddress != address(0), "zero address");
            require(user.totalTokens == 0, "some users are already whitelisted");

            user.totalTokens = userTotalTokens[i];
            user.firstUnlockTokens = _applyPercentage(userTotalTokens[i], firstUnlockPercentage).toUint128();
            user.linearVestingOffset = getLinearVestingOffset().toUint32();
            user.linearVestingPeriod = getLinearVestingPeriod().toUint32();
            user.linearUnlocksCount = getLinearUnlocksCount().toUint32();

            _totalTokens += userTotalTokens[i];
            emit Whitelist(userAddress, userTotalTokens[i]);
        }
        totalTokens += _totalTokens;

        if (last) {
            whitelistingAllowed = false;
        }
    }

    /**
        Decreases user total tokens by a given amount and sends them to burn address.
     */
    function burnUserTokens(address userAddress, uint amount) external onlyOwner nonReentrant {
        _updateUserVestingSchedule(userAddress);
        uint burned = _updateUserTotalTokens(userAddress, amount);
        require(burned > 0, "nothing to burn");

        totalBurned += burned.toUint128();
        vestingToken.safeTransfer(BURN_ADDRESS, burned);
        emit BurnUserTokens(userAddress, burned);
    }

    // =================== EXTERNAL FUNCTIONS  =================== //

    /**
        Claim for the caller with no extra claim amount.
     */
    function claim() external {
        _claim(msg.sender, 0);

    }

    /**
        Claim for any user but only with no extra claim amount.
     */
    function claimFor(address userAddress) external {
        _claim(userAddress, 0);
        
    }

    /**
        Claim all unlocked amount with some amount from locked tokens. Claiming tokens from locked causes a fee.
     */
    function claimWithExtra(uint extraClaimAmount) external  {
        _claim(msg.sender, extraClaimAmount);
    }

    // =================== INTERNAL FUNCTIONS  =================== //

    function _claim(address userAddress, uint extraClaimAmount) internal nonReentrant {
        _updateUserVestingSchedule(userAddress);

        uint maxExtraClaimAmount = getClaimableFromLocked(userAddress);
        require(extraClaimAmount <= maxExtraClaimAmount, "requested claim amount > max claimable");

        User storage user = users[userAddress];
        uint baseClaimAmount = getClaimable(userAddress);
        uint feeRate = getFeeRate();
        uint fee = feeRate < HUNDRED_PERCENT ? extraClaimAmount * feeRate / (HUNDRED_PERCENT - feeRate) : 0;
        require(baseClaimAmount + extraClaimAmount > 0, "nothing to claim");

        _updateUserTotalTokens(userAddress, extraClaimAmount + fee);
        user.totalClaimedFromUnlocked += baseClaimAmount.toUint128();
        user.totalExtraClaimed += extraClaimAmount.toUint128();
        user.totalFee += fee.toUint128();

        uint claimAmount = baseClaimAmount + extraClaimAmount;
        
        totalClaimed += claimAmount.toUint128();
        totalFee += fee.toUint128();

        vestingToken.safeTransfer(userAddress, claimAmount);
        if (fee > 0) {
            uint feeSplit1 = _applyPercentage(fee, feeSplitPercentage);
            uint feeSplit2 = fee - feeSplit1;
            vestingToken.safeTransfer(feeCollector1, feeSplit1);
            vestingToken.safeTransfer(feeCollector2, feeSplit2);
        }

        emit Claim(userAddress, baseClaimAmount, extraClaimAmount, fee);
    }

    /**
        @dev Decreases user total tokens and updates vesting schedule accordingly.
     */
    function _updateUserTotalTokens(address userAddress, uint amount) internal returns (uint) {
        User storage user = users[userAddress];
        uint unlocked = getUnlocked(userAddress);
        uint maxAmount = user.totalTokens - unlocked;
        if (amount > maxAmount) {
            amount = maxAmount;
        }

        if (amount == 0) {
            return 0;
        }

        uint linearUnlocksPassed = _getLinearUnlocksPassed(user, 0);
        user.firstUnlockTokens = unlocked.toUint128();
        user.linearVestingOffset += (getLinearVestingPeriod() * linearUnlocksPassed).toUint32();
        user.linearUnlocksCount -= linearUnlocksPassed.toUint32();
        user.totalTokens -= amount.toUint128();

        return amount;
    }

    /**
        @dev Syncs user vesting schedule with the updated global vesting schedule.
     */
    function _updateUserVestingSchedule(address userAddress) internal {
        require(block.timestamp > startTime, "vesting hasn't started");
        users[userAddress] = _getUpdatedUserVestingSchedule(userAddress);
    }

    // =================== VIEW FUNCTIONS  =================== //

    /**
        @dev Substracts claimed amount from unlocked and returns it. 
     */
    function getClaimable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return getUnlocked(userAddress) - user.totalClaimedFromUnlocked;
    }

    /**
        @dev Applies feeRate to locked tokens and returns it. (= how many tokens can user maximally claim from locked)
     */
    function getClaimableFromLocked(address userAddress) public view returns (uint) {
        return _applyPercentage(getLocked(userAddress), HUNDRED_PERCENT - getFeeRate());
    }

    /**
        @dev Returns a value between feeRateStart and feeRateEnd based on vested time.
     */
    function getFeeRate() public view returns (uint) {
        uint linearUnlocksCount = getLinearUnlocksCount();
        if (feeRateStart == feeRateEnd || linearUnlocksCount == 0) {
            return feeRateEnd;
        }

        uint vestedTime = _getVestedTime(0);
        uint totalVestingTime = _calculateTotalVestingTime(getLinearVestingOffset(), getLinearVestingPeriod(), linearUnlocksCount);

        if (vestedTime < totalVestingTime && totalVestingTime > 0) {
            uint feeRate = feeRateStart;
            uint feeRateDiff = feeRateStart - feeRateEnd;
            feeRate -= vestedTime * feeRateDiff / totalVestingTime;
            return feeRate;
        } else {
            return feeRateEnd;
        }
    }

    function getUnlocked(address userAddress) public view returns (uint) {
        User memory user = _getUpdatedUserVestingSchedule(userAddress);
        return _getUnlocked(user, 0);
    }

    /**
        @dev Returns how many tokens a given user has locked (=remaining vested).
     */
    function getLocked(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.totalTokens - getUnlocked(userAddress);
    }

    /**
        @dev Returns the currently last linear vesting offset.
     */
    function getLinearVestingOffset() public view returns (uint) {
        return vestingScheduleStates[vestingScheduleStates.length - 1].linearVestingOffset;
    }

    /**
        @dev Returns the currently last linear vesting period.
     */
    function getLinearVestingPeriod() public view returns (uint) {
        return vestingScheduleStates[vestingScheduleStates.length - 1].linearVestingPeriod;
    }

    /**
        @dev Returns the currently last linear unlocks count.
     */
    function getLinearUnlocksCount() public view returns (uint) {
        return vestingScheduleStates[vestingScheduleStates.length - 1].linearUnlocksCount;
    }

    /**
        @dev Returns the passed time from start time at a given timestamp. (timestampAt 0 is converted to block.timestamp) 
     */

    function _getVestedTime(uint timestampAt) internal view returns (uint) {
        uint currentTime = timestampAt > 0 ? timestampAt : block.timestamp;
        return currentTime > startTime ? currentTime - startTime : 0;
    }

    /**
        @dev Returns how many linear unlocks have passed at given timestamp. (timestampAt 0 is converted to block.timestamp) 
     */
    function _getLinearUnlocksPassed(User memory user, uint timestampAt) internal view returns (uint) {
        uint linearVestingPeriod = user.totalTokens > 0 ? user.linearVestingPeriod : getLinearVestingPeriod();
        if (linearVestingPeriod == 0) {
            return  user.totalTokens > 0 ? user.linearUnlocksCount : getLinearUnlocksCount();
        }

        uint linearVestingOffset = user.totalTokens > 0 ? user.linearVestingOffset : getLinearVestingOffset();
        uint linearUnlocksCount = user.totalTokens > 0 ? user.linearUnlocksCount : getLinearUnlocksCount();
        uint vestedTime = _getVestedTime(timestampAt);
        uint linearVestedTime;
        if (vestedTime > linearVestingOffset) {
            linearVestedTime = vestedTime - linearVestingOffset;
        }

        uint linearUnlocksPassed = linearVestedTime / linearVestingPeriod + (linearVestedTime > 0 ? 1 : 0);
        if (linearUnlocksPassed > linearUnlocksCount) {
            linearUnlocksPassed = linearUnlocksCount;
        }
        return linearUnlocksPassed;
    }

    function _applyPercentage(uint value, uint percentage) internal pure returns (uint) {
        return value * percentage / HUNDRED_PERCENT;
    }

    /**
        @dev Returns the total duration of the vesting based on inputs. 
     */
    function _calculateTotalVestingTime(uint linearVestingOffset, uint linearVestingPeriod, uint linearUnlocksCount) internal pure returns (uint) {
        if (linearUnlocksCount == 0) {
            return 0;
        }
        return linearVestingOffset + linearVestingPeriod * (linearUnlocksCount - 1);
    }

    /**
        @dev Checks whether the vesting schedule wasn't shortened or prolonged too much.
     */
    function _validateVestingSchedule() internal view {
        uint previousVestingScheduleIndex = vestingScheduleStates.length - 2;
        uint totalVestingTime = _calculateTotalVestingTime(getLinearVestingOffset(), getLinearVestingPeriod(), getLinearUnlocksCount());
        uint totalVestingTimePrevious = _calculateTotalVestingTime(
            vestingScheduleStates[previousVestingScheduleIndex].linearVestingOffset, 
            vestingScheduleStates[previousVestingScheduleIndex].linearVestingPeriod, 
            vestingScheduleStates[previousVestingScheduleIndex].linearUnlocksCount
        );
        
        require(totalVestingTime > totalVestingTimePrevious, "shortened");
        require(totalVestingTime <= totalVestingTimePrevious + 52 weeks, "prolonged too much");
    }

    /**
        @dev The important part here is `firstUnlockTokens` is calculated in each loop (This assures that 
            there is no difference in claiming before or after the vesting schedule changes)
     */
    function _getUpdatedUserVestingSchedule(address userAddress) internal view returns (User memory user) {
        user = users[userAddress];
        uint32 userLastIndex = user.vestingScheduleUpdatedIndex;

        while (userLastIndex < vestingScheduleStates.length - 1) {
            userLastIndex++;
            user.firstUnlockTokens = _getUnlocked(user, vestingScheduleStates[userLastIndex].timestamp).toUint128();
            user.linearVestingOffset = vestingScheduleStates[userLastIndex].linearVestingOffset;
            user.linearVestingPeriod = vestingScheduleStates[userLastIndex].linearVestingPeriod;
            user.linearUnlocksCount = vestingScheduleStates[userLastIndex].linearUnlocksCount;
            user.vestingScheduleUpdatedIndex = userLastIndex;
        }
    }

    /**
        @dev Returns how many tokens a given user can absolutely (=doens't include already claimed tokens) 
        claim at a given timestamp. (timestampAt 0 is converted to block.timestamp) 
     */
    function _getUnlocked(User memory user, uint timestampAt) internal view returns (uint) {
        uint vestedTime = _getVestedTime(timestampAt);
        if (vestedTime == 0) {
            return 0;
        }
        
        uint unlocked;
        if (user.linearUnlocksCount > 0) {
            uint firstUnlockTokens = user.firstUnlockTokens;
            uint linearUnlocksTokens = user.totalTokens - firstUnlockTokens;
            uint linearUnlocksPassed = _getLinearUnlocksPassed(user, timestampAt);
            unlocked = firstUnlockTokens + linearUnlocksTokens * linearUnlocksPassed / user.linearUnlocksCount;
        } else {
            unlocked = user.totalTokens;
        }

        if (unlocked > user.totalTokens) {
            unlocked = user.totalTokens;
        }

        return unlocked;
    }
}