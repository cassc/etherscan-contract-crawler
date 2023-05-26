// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IERC20Decimals.sol";

/**
    @title A smart contract for unlocking tokens based on a release schedule
    @author By CoMakery, Inc., Upside, Republic
    @dev When deployed the contract is as a proxy for a single token that it creates release schedules for
        it implements the ERC20 token interface to integrate with wallets but it is not an independent token.
        The token must implement a burn function.
*/
contract TokenLockup {
    using SafeERC20 for IERC20Decimals;

    IERC20Decimals immutable public token;
    string private _name;
    string private _symbol;

    struct ReleaseSchedule {
        uint releaseCount;
        uint delayUntilFirstReleaseInSeconds;
        uint initialReleasePortionInBips;
        uint periodBetweenReleasesInSeconds;
    }

    struct Timelock {
        uint scheduleId;
        uint commencementTimestamp;
        uint tokensTransferred;
        uint totalAmount;
        address[] cancelableBy; // not cancelable unless set at the time of funding
    }

    ReleaseSchedule[] public releaseSchedules;
    uint immutable public minTimelockAmount;
    uint immutable public maxReleaseDelay;
    uint private constant BIPS_PRECISION = 10000;

    mapping(address => Timelock[]) public timelocks;
    mapping(address => uint) internal _totalTokensUnlocked;
    mapping(address => mapping(address => uint)) internal _allowances;

    event Approval(address indexed from, address indexed spender, uint amount);
    event ScheduleCreated(address indexed from, uint indexed scheduleId);

    event ScheduleFunded(
        address indexed from,
        address indexed to,
        uint indexed scheduleId,
        uint amount,
        uint commencementTimestamp,
        uint timelockId,
        address[] cancelableBy
    );

    event TimelockCanceled(
        address indexed canceledBy,
        address indexed target,
        uint indexed timelockIndex,
        address relaimTokenTo,
        uint canceledAmount,
        uint paidAmount
    );

    /**
        @dev Configure deployment for a specific token with release schedule security parameters
        @param _token The address of the token that will be released on the lockup schedule
        @param name_ TokenLockup ERC20 interface name. Should be Distinct from token. Example: "Token Name Lockup"
        @param symbol_ TokenLockup ERC20 interface symbol. Should be distinct from token symbol. Example: "TKN LOCKUP"
        @dev The symbol should end with " Unlock" & be less than 11 characters for MetaMask "custom token" compatibility
    */
    constructor (
        address _token,
        string memory name_,
        string memory symbol_,
        uint _minTimelockAmount,
        uint _maxReleaseDelay
    ) {
        _name = name_;
        _symbol = symbol_;
        token = IERC20Decimals(_token);

        require(_minTimelockAmount > 0, "Min timelock amount > 0");
        minTimelockAmount = _minTimelockAmount;
        maxReleaseDelay = _maxReleaseDelay;
    }

    /**
        @notice Create a release schedule template that can be used to generate many token timelocks
        @param releaseCount Total number of releases including any initial "cliff'
        @param delayUntilFirstReleaseInSeconds "cliff" or 0 for immediate release
        @param initialReleasePortionInBips Portion to release in 100ths of 1% (10000 BIPS per 100%)
        @param periodBetweenReleasesInSeconds After the delay and initial release
            the remaining tokens will be distributed evenly across the remaining number of releases (releaseCount - 1)
        @return unlockScheduleId The id used to refer to the release schedule at the time of funding the schedule
    */
    function createReleaseSchedule(
        uint releaseCount,
        uint delayUntilFirstReleaseInSeconds,
        uint initialReleasePortionInBips,
        uint periodBetweenReleasesInSeconds
    ) external returns (uint unlockScheduleId) {
        require(delayUntilFirstReleaseInSeconds <= maxReleaseDelay, "first release > max");
        require(releaseCount >= 1, "< 1 release");
        require(initialReleasePortionInBips <= BIPS_PRECISION, "release > 100%");

        if (releaseCount > 1) {
            require(periodBetweenReleasesInSeconds > 0, "period = 0");
        } else if (releaseCount == 1) {
            require(initialReleasePortionInBips == BIPS_PRECISION, "released < 100%");
        }

        releaseSchedules.push(ReleaseSchedule(
            releaseCount,
            delayUntilFirstReleaseInSeconds,
            initialReleasePortionInBips,
            periodBetweenReleasesInSeconds
        ));

        unlockScheduleId = releaseSchedules.length - 1;
        emit ScheduleCreated(msg.sender, unlockScheduleId);

        return unlockScheduleId;
    }

    /**
        @notice Fund the programmatic release of tokens to a recipient.
            WARNING: this function IS CANCELABLE by cancelableBy.
            If canceled the tokens that are locked at the time of the cancellation will be returned to the funder
            and unlocked tokens will be transferred to the recipient.
        @param to recipient address that will have tokens unlocked on a release schedule
        @param amount of tokens to transfer in base units (the smallest unit without the decimal point)
        @param commencementTimestamp the time the release schedule will start
        @param scheduleId the id of the release schedule that will be used to release the tokens
        @param cancelableBy array of canceler addresses
        @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
    */
    function fundReleaseSchedule(
        address to,
        uint amount,
        uint commencementTimestamp, // unix timestamp
        uint scheduleId,
        address[] memory cancelableBy
    ) public returns (bool success) {
        require(cancelableBy.length <= 10, "max 10 cancelableBy addressees");

        uint timelockId = _fund(to, amount, commencementTimestamp, scheduleId);

        if (cancelableBy.length > 0) {
            timelocks[to][timelockId].cancelableBy = cancelableBy;
        }

        emit ScheduleFunded(msg.sender, to, scheduleId, amount, commencementTimestamp, timelockId, cancelableBy);
        return true;
    }

    function _fund(
        address to,
        uint amount,
        uint commencementTimestamp, // unix timestamp
        uint scheduleId)
    internal returns (uint) {
        require(amount >= minTimelockAmount, "amount < min funding");
        require(to != address(0), "to 0 address");
        require(scheduleId < releaseSchedules.length, "bad scheduleId");
        require(amount >= releaseSchedules[scheduleId].releaseCount, "< 1 token per release");
        // It will revert via ERC20 implementation if there's no allowance
        token.safeTransferFrom(msg.sender, address(this), amount);

        require(
            commencementTimestamp + releaseSchedules[scheduleId].delayUntilFirstReleaseInSeconds <=
            block.timestamp + maxReleaseDelay
        , "initial release out of range");

        Timelock memory timelock;
        timelock.scheduleId = scheduleId;
        timelock.commencementTimestamp = commencementTimestamp;
        timelock.totalAmount = amount;

        timelocks[to].push(timelock);
        return timelockCountOf(to) - 1;
    }

    /**
        @notice Cancel a cancelable timelock created by the fundReleaseSchedule function.
            WARNING: this function cannot cancel a release schedule created by fundReleaseSchedule
            If canceled the tokens that are locked at the time of the cancellation will be returned to the funder
            and unlocked tokens will be transferred to the recipient.
        @param target The address that would receive the tokens when released from the timelock.
        @param timelockIndex timelock index
        @param target The address that would receive the tokens when released from the timelock
        @param scheduleId require it matches expected
        @param commencementTimestamp require it matches expected
        @param totalAmount require it matches expected
        @param reclaimTokenTo reclaim token to
        @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
    */
    function cancelTimelock(
        address target,
        uint timelockIndex,
        uint scheduleId,
        uint commencementTimestamp,
        uint totalAmount,
        address reclaimTokenTo
    ) public returns (bool success) {
        require(timelockCountOf(target) > timelockIndex, "invalid timelock");
        require(reclaimTokenTo != address(0), "Invalid reclaimTokenTo");

        Timelock storage timelock = timelocks[target][timelockIndex];

        require(_canBeCanceled(timelock), "You are not allowed to cancel this timelock");
        require(timelock.scheduleId == scheduleId, "Expected scheduleId does not match");
        require(timelock.commencementTimestamp == commencementTimestamp, "Expected commencementTimestamp does not match");
        require(timelock.totalAmount == totalAmount, "Expected totalAmount does not match");

        uint canceledAmount = lockedBalanceOfTimelock(target, timelockIndex);

        require(canceledAmount > 0, "Timelock has no value left");

        uint paidAmount = unlockedBalanceOfTimelock(target, timelockIndex);

        token.safeTransfer(reclaimTokenTo, canceledAmount);
        token.safeTransfer(target, paidAmount);

        emit TimelockCanceled(msg.sender, target, timelockIndex, reclaimTokenTo, canceledAmount, paidAmount);

        timelock.tokensTransferred = timelock.totalAmount;
        return true;
    }

    /**
     *  @notice Check if timelock can be cancelable by msg.sender
     */
    function _canBeCanceled(Timelock storage timelock) view private returns (bool){
        for (uint i = 0; i < timelock.cancelableBy.length; i++) {
            if (msg.sender == timelock.cancelableBy[i]) {
                return true;
            }
        }
        return false;
    }

    /**
     *  @notice Batch version of fund cancelable release schedule
     *  @param to An array of recipient address that will have tokens unlocked on a release schedule
     *  @param amounts An array of amount of tokens to transfer in base units (the smallest unit without the decimal point)
     *  @param commencementTimestamps An array of the time the release schedule will start
     *  @param scheduleIds An array of the id of the release schedule that will be used to release the tokens
     *  @param cancelableBy An array of cancelables
     *  @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
     */
    function batchFundReleaseSchedule(
        address[] calldata to,
        uint[] calldata amounts,
        uint[] calldata commencementTimestamps,
        uint[] calldata scheduleIds,
        address[] calldata cancelableBy
    ) external returns (bool success) {
        require(to.length == amounts.length, "mismatched array length");
        require(to.length == commencementTimestamps.length, "mismatched array length");
        require(to.length == scheduleIds.length, "mismatched array length");

        for (uint i = 0; i < to.length; i++) {
            require(fundReleaseSchedule(
                to[i],
                amounts[i],
                commencementTimestamps[i],
                scheduleIds[i],
                cancelableBy
            ));
        }

        return true;
    }

    /**
        @notice Get The total locked balance of an address for all timelocks
        @param who Address to calculate
        @return amount The total locked amount of tokens for all of the who address's timelocks
    */
    function lockedBalanceOf(address who) public view returns (uint amount) {
        for (uint i = 0; i < timelockCountOf(who); i++) {
            amount += lockedBalanceOfTimelock(who, i);
        }
        return amount;
    }
    /**
        @notice Get The total unlocked balance of an address for all timelocks
        @param who Address to calculate
        @return amount The total unlocked amount of tokens for all of the who address's timelocks
    */
    function unlockedBalanceOf(address who) public view returns (uint amount) {
        for (uint i = 0; i < timelockCountOf(who); i++) {
            amount += unlockedBalanceOfTimelock(who, i);
        }
        return amount;
    }

    /**
        @notice Get The locked balance for a specific address and specific timelock
        @param who The address to check
        @param timelockIndex Specific timelock belonging to the who address
        @return locked Balance of the timelock
    */
    function lockedBalanceOfTimelock(address who, uint timelockIndex) public view returns (uint locked) {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return timelock.totalAmount - totalUnlockedToDateOfTimelock(who, timelockIndex);
        }
    }

    /**
        @notice Get the unlocked balance for a specific address and specific timelock
        @param who the address to check
        @param timelockIndex for a specific timelock belonging to the who address
        @return unlocked balance of the timelock
    */
    function unlockedBalanceOfTimelock(address who, uint timelockIndex) public view returns (uint unlocked) {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return totalUnlockedToDateOfTimelock(who, timelockIndex) - timelock.tokensTransferred;
        }
    }

    /**
        @notice Check the total remaining balance of a timelock including the locked and unlocked portions
        @param who the address to check
        @param timelockIndex  Specific timelock belonging to the who address
        @return total remaining balance of a timelock
     */
    function balanceOfTimelock(address who, uint timelockIndex) external view returns (uint) {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return timelock.totalAmount - timelock.tokensTransferred;
        }
    }

    /**
        @notice Gets the total locked and unlocked balance of a specific address's timelocks
        @param who The address to check
        @param timelockIndex The index of the timelock for the who address
        @return total Locked and unlocked amount for the specified timelock
    */
    function totalUnlockedToDateOfTimelock(address who, uint timelockIndex) public view returns (uint total) {
        Timelock memory _timelock = timelockOf(who, timelockIndex);

        return calculateUnlocked(
            _timelock.commencementTimestamp,
            block.timestamp,
            _timelock.totalAmount,
            _timelock.scheduleId
        );
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
    */
    function balanceOf(address who) external view returns (uint) {
        return unlockedBalanceOf(who) + lockedBalanceOf(who);
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
    */
    function transfer(address to, uint value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }
    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
    */
    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(_allowances[from][msg.sender] >= value, "value > allowance");
        _allowances[from][msg.sender] -= value;
        return _transfer(from, to, value);
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
        @dev Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    */
    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
        @dev Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
        @dev Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    */
    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
        @dev Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    */
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "decrease > allowance");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
    /**
        @notice ERC20 details interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
         @dev this function returns the decimals of the token contract that the TokenLockup proxies
    */
    function decimals() public view returns (uint8) {
        return token.decimals();
    }

    /// @notice ERC20 standard interfaces function
    /// @return The name of the TokenLockup contract.
    ///     WARNING: this is different than the underlying token that the TokenLockup is a proxy for.
    function name() public view returns (string memory) {
        return _name;
    }

    /// @notice ERC20 standard interfaces function
    /// @return The symbol of the TokenLockup contract.
    ///     WARNING: this is different than the underlying token that the TokenLockup is a proxy for.
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    /// @notice ERC20 standard interface function.
    /// @return Total of tokens for all timelocks and all addresses held by the TokenLockup smart contract.
    function totalSupply() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    function _transfer(address from, address to, uint value) internal returns (bool) {
        require(unlockedBalanceOf(from) >= value, "amount > unlocked");

        uint remainingTransfer = value;

        // transfer from unlocked tokens
        for (uint i = 0; i < timelockCountOf(from); i++) {
            // if the timelock has no value left
            if (timelocks[from][i].tokensTransferred == timelocks[from][i].totalAmount) {
                continue;
            } else if (remainingTransfer > unlockedBalanceOfTimelock(from, i)) {
                // if the remainingTransfer is more than the unlocked balance use it all
                remainingTransfer -= unlockedBalanceOfTimelock(from, i);
                timelocks[from][i].tokensTransferred += unlockedBalanceOfTimelock(from, i);
            } else {
                // if the remainingTransfer is less than or equal to the unlocked balance
                // use part or all and exit the loop
                timelocks[from][i].tokensTransferred += remainingTransfer;
                remainingTransfer = 0;
                break;
            }
        }

        // should never have a remainingTransfer amount at this point
        require(remainingTransfer == 0, "bad transfer");

        token.safeTransfer(to, value);
        return true;
    }

    /**
        @notice transfers the unlocked token from an address's specific timelock
            It is typically more convenient to call transfer. But if the account has many timelocks the cost of gas
            for calling transfer may be too high. Calling transferTimelock from a specific timelock limits the transfer cost.
        @param to the address that the tokens will be transferred to
        @param value the number of token base units to me transferred to the to address
        @param timelockId the specific timelock of the function caller to transfer unlocked tokens from
        @return bool always true when completed
    */
    function transferTimelock(address to, uint value, uint timelockId) public returns (bool) {
        require(unlockedBalanceOfTimelock(msg.sender, timelockId) >= value, "amount > unlocked");
        timelocks[msg.sender][timelockId].tokensTransferred += value;
        token.safeTransfer(to, value);
        return true;
    }

    /**
        @notice calculates how many tokens would be released at a specified time for a scheduleId.
            This is independent of any specific address or address's timelock.

        @param commencedTimestamp the commencement time to use in the calculation for the scheduled
        @param currentTimestamp the timestamp to calculate unlocked tokens for
        @param amount the amount of tokens
        @param scheduleId the schedule id used to calculate the unlocked amount
        @return unlocked the total amount unlocked for the schedule given the other parameters
    */
    function calculateUnlocked(
        uint commencedTimestamp,
        uint currentTimestamp,
        uint amount,
        uint scheduleId
    ) public view returns (uint unlocked) {
        return calculateUnlocked(commencedTimestamp, currentTimestamp, amount, releaseSchedules[scheduleId]);
    }

    // Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "owner is 0 address");
        require(spender != address(0), "spender is 0 address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // @notice the total number of schedules that have been created
    function scheduleCount() external view returns (uint count) {
        return releaseSchedules.length;
    }

    /**
        @notice Get the struct details for an address's specific timelock
        @param who Address to check
        @param index The index of the timelock for the who address
        @return timelock Struct with the attributes of the timelock
    */
    function timelockOf(address who, uint index) public view returns (Timelock memory timelock) {
        return timelocks[who][index];
    }

    // @notice returns the total count of timelocks for a specific address
    function timelockCountOf(address who) public view returns (uint) {
        return timelocks[who].length;
    }

    /**
        @notice calculates how many tokens would be released at a specified time for a ReleaseSchedule struct.
            This is independent of any specific address or address's timelock.

        @param commencedTimestamp the commencement time to use in the calculation for the scheduled
        @param currentTimestamp the timestamp to calculate unlocked tokens for
        @param amount the amount of tokens
        @param releaseSchedule a ReleaseSchedule struct used to calculate the unlocked amount
        @return unlocked the total amount unlocked for the schedule given the other parameters
    */
    function calculateUnlocked(
        uint commencedTimestamp,
        uint currentTimestamp,
        uint amount,
        ReleaseSchedule memory releaseSchedule)
    public pure returns (uint unlocked) {
        return calculateUnlocked(
            commencedTimestamp,
            currentTimestamp,
            amount,
            releaseSchedule.releaseCount,
            releaseSchedule.delayUntilFirstReleaseInSeconds,
            releaseSchedule.initialReleasePortionInBips,
            releaseSchedule.periodBetweenReleasesInSeconds
        );
    }

    /**
        @notice The same functionality as above function with spread format of `releaseSchedule` arg
        @param commencedTimestamp the commencement time to use in the calculation for the scheduled
        @param currentTimestamp the timestamp to calculate unlocked tokens for
        @param amount the amount of tokens
        @param releaseCount Total number of releases including any initial "cliff'
        @param delayUntilFirstReleaseInSeconds "cliff" or 0 for immediate release
        @param initialReleasePortionInBips Portion to release in 100ths of 1% (10000 BIPS per 100%)
        @param periodBetweenReleasesInSeconds After the delay and initial release
        @return unlocked the total amount unlocked for the schedule given the other parameters
    */
    function calculateUnlocked(
        uint commencedTimestamp,
        uint currentTimestamp,
        uint amount,
        uint releaseCount,
        uint delayUntilFirstReleaseInSeconds,
        uint initialReleasePortionInBips,
        uint periodBetweenReleasesInSeconds
    ) public pure returns (uint unlocked) {
        if (commencedTimestamp > currentTimestamp) {
            return 0;
        }
        uint secondsElapsed = currentTimestamp - commencedTimestamp;

        // return the full amount if the total lockup period has expired
        // unlocked amounts in each period are truncated and round down remainders smaller than the smallest unit
        // unlocking the full amount unlocks any remainder amounts in the final unlock period
        // this is done first to reduce computation
        if (
            secondsElapsed >= delayUntilFirstReleaseInSeconds +
            (periodBetweenReleasesInSeconds * (releaseCount - 1))
        ) {
            return amount;
        }

        // unlock the initial release if the delay has elapsed
        if (secondsElapsed >= delayUntilFirstReleaseInSeconds) {
            unlocked = (amount * initialReleasePortionInBips) / BIPS_PRECISION;

            // if at least one period after the delay has passed
            if (secondsElapsed - delayUntilFirstReleaseInSeconds >= periodBetweenReleasesInSeconds) {

                // calculate the number of additional periods that have passed (not including the initial release)
                // this discards any remainders (ie it truncates / rounds down)
                uint additionalUnlockedPeriods = (secondsElapsed - delayUntilFirstReleaseInSeconds) / periodBetweenReleasesInSeconds;

                // calculate the amount of unlocked tokens for the additionalUnlockedPeriods
                // multiplication is applied before division to delay truncating to the smallest unit
                // this distributes unlocked tokens more evenly across unlock periods
                // than truncated division followed by multiplication
                unlocked += ((amount - unlocked) * additionalUnlockedPeriods) / (releaseCount - 1);
            }
        }

        return unlocked;
    }
}