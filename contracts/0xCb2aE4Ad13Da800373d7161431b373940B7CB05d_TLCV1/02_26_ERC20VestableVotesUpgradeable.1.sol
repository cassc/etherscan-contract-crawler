//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

import "../interfaces/components/IERC20VestableVotesUpgradeable.1.sol";

import "../state/tlc/VestingSchedules.2.sol";

import "../libraries/LibSanitize.sol";
import "../libraries/LibUint256.sol";

/// @title ERC20VestableVotesUpgradeableV1
/// @author Alluvial
/// @notice This is an ERC20 extension that
/// @notice   - can be used as source of vote power (inherited from OpenZeppelin ERC20VotesUpgradeable)
/// @notice   - can delegate vote power from an account to another account (inherited from OpenZeppelin ERC20VotesUpgradeable)
/// @notice   - can manage token vestings: ownership is progressively transferred to a beneficiary according to a vesting schedule
/// @notice   - keeps a history (checkpoints) of each account's vote power
/// @notice
/// @notice Notes from OpenZeppelin [ERC20VotesUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol)
/// @notice   - vote power can be delegated either by calling the {delegate} function, or by providing a signature to be used with {delegateBySig}
/// @notice   - keeps a history (checkpoints) of each account's vote power
/// @notice   - power can be queried through the public accessors {getVotes} and {getPastVotes}.
/// @notice   - by default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
/// @notice requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
/// @notice
/// @notice Notes about token vesting
/// @notice   - any token holder can call the method {createVestingSchedule} in order to transfer tokens to a beneficiary according to a vesting schedule. When
/// @notice     creating a vesting schedule, tokens are transferred to an escrow that holds the token while the vesting progresses. Voting power of the escrowed token is delegated to the
/// @notice     beneficiary or a delegatee account set by the vesting schedule creator
/// @notice   - the schedule beneficiary call {releaseVestingSchedule} to get vested tokens transferred from escrow
/// @notice   - the schedule creator can revoke a revocable schedule by calling {revokeVestingSchedule} in which case the non-vested tokens are transfered from the escrow back to the creator
/// @notice   - the schedule beneficiary can delegate escrow voting power to any account by calling {delegateVestingEscrow}
/// @notice
/// @notice Vesting schedule attributes are
/// @notice   - start : start time of the vesting period
/// @notice   - cliff duration: duration before which first tokens gets ownable
/// @notice   - total duration: duration of the entire vesting (sum of all vesting period durations)
/// @notice   - period duration: duration of a single period of vesting
/// @notice   - lock duration: duration before tokens gets unlocked. can exceed the duration of the vesting chedule
/// @notice   - amount: amount of tokens granted by the vesting schedule
/// @notice   - beneficiary: beneficiary of tokens after they are releaseVestingScheduled
/// @notice   - revocable: whether the schedule can be revoked
/// @notice
/// @notice Vesting schedule
/// @notice   - if currentTime < cliff: vestedToken = 0
/// @notice   - if cliff <= currentTime < end: vestedToken = (vestedPeriodCount(currentTime) * periodDuration * amount) / totalDuration
/// @notice   - if end < currentTime: vestedToken = amount
/// @notice
/// @notice Remark: After cliff new tokens get vested at the end of each period
/// @notice
/// @notice Vested token & lock period
/// @notice   - a vested token is a token that will be eventually releasable from the escrow to the beneficiary once the lock period is over
/// @notice   - lock period prevents beneficiary from releasing vested tokens before the lock period ends. Vested tokens
/// @notice will eventually be releasable once the lock period is over
/// @notice
/// @notice Example: Joe gets a vesting starting on Jan 1st 2022 with duration of 1 year and a lock period of 2 years.
/// @notice On Jan 1st 2023, Joe will have all tokens vested but can not yet release it due to the lock period.
/// @notice On Jan 1st 2024, lock period is over and Joe can release all tokens.
abstract contract ERC20VestableVotesUpgradeableV1 is
    Initializable,
    IERC20VestableVotesUpgradeableV1,
    ERC20VotesUpgradeable
{
    // internal used to compute the address of the escrow
    bytes32 internal constant ESCROW = bytes32(uint256(keccak256("escrow")) - 1);

    function __ERC20VestableVotes_init() internal onlyInitializing {}

    function __ERC20VestableVotes_init_unchained() internal onlyInitializing {}

    /// @notice This method migrates the state of the vesting schedules from V1 to V2
    /// @dev This method should be used if deployment with the old version using V1 state models is upgraded
    function migrateVestingSchedulesFromV1ToV2() internal {
        if (VestingSchedulesV2.getCount() == 0) {
            uint256 existingV1VestingSchedules = VestingSchedulesV1.getCount();
            for (uint256 idx; idx < existingV1VestingSchedules;) {
                uint256 scheduleAmount = VestingSchedulesV1.get(idx).amount;
                uint256 releasedAmount =
                    scheduleAmount - LibUint256.min(balanceOf(_deterministicVestingEscrow(idx)), scheduleAmount);
                VestingSchedulesV2.migrateVestingScheduleFromV1(idx, releasedAmount);
                unchecked {
                    ++idx;
                }
            }
        }
    }

    /// @inheritdoc IERC20VestableVotesUpgradeableV1
    function getVestingSchedule(uint256 _index) external view returns (VestingSchedulesV2.VestingSchedule memory) {
        return VestingSchedulesV2.get(_index);
    }

    /// @inheritdoc IERC20VestableVotesUpgradeableV1
    function getVestingScheduleCount() external view returns (uint256) {
        return VestingSchedulesV2.getCount();
    }

    /// @inheritdoc IERC20VestableVotesUpgradeableV1
    function vestingEscrow(uint256 _index) external view returns (address) {
        return _deterministicVestingEscrow(_index);
    }

    /// @inheritdoc IERC20VestableVotesUpgradeableV1
    function computeVestingReleasableAmount(uint256 _index) external view returns (uint256) {
        VestingSchedulesV2.VestingSchedule memory vestingSchedule = VestingSchedulesV2.get(_index);

        uint256 time = _getCurrentTime();
        if (time < (vestingSchedule.start + vestingSchedule.lockDuration)) {
            return 0;
        }

        return _computeVestingReleasableAmount(vestingSchedule, time);
    }

    /// @inheritdoc IERC20VestableVotesUpgradeableV1
    function computeVestingVestedAmount(uint256 _index) external view returns (uint256) {
        VestingSchedulesV2.VestingSchedule memory vestingSchedule = VestingSchedulesV2.get(_index);
        return _computeVestedAmount(vestingSchedule, LibUint256.min(_getCurrentTime(), vestingSchedule.end));
    }

    /// @inheritdoc IERC20VestableVotesUpgradeableV1
    function createVestingSchedule(
        uint64 _start,
        uint32 _cliffDuration,
        uint32 _duration,
        uint32 _periodDuration,
        uint32 _lockDuration,
        bool _revocable,
        uint256 _amount,
        address _beneficiary,
        address _delegatee
    ) external returns (uint256) {
        return _createVestingSchedule(
            msg.sender,
            _beneficiary,
            _delegatee,
            _start,
            _cliffDuration,
            _duration,
            _periodDuration,
            _lockDuration,
            _revocable,
            _amount
        );
    }

    /// @inheritdoc IERC20VestableVotesUpgradeableV1
    function revokeVestingSchedule(uint256 _index, uint64 _end) external returns (uint256) {
        return _revokeVestingSchedule(_index, _end);
    }

    /// @inheritdoc IERC20VestableVotesUpgradeableV1
    function releaseVestingSchedule(uint256 _index) external returns (uint256) {
        return _releaseVestingSchedule(_index);
    }

    /// @inheritdoc IERC20VestableVotesUpgradeableV1
    function delegateVestingEscrow(uint256 _index, address _delegatee) external returns (bool) {
        return _delegateVestingEscrow(_index, _delegatee);
    }

    /// @notice Creates a new vesting schedule
    /// @param _creator creator of the token vesting
    /// @param _beneficiary beneficiary of tokens after they are releaseVestingScheduled
    /// @param _delegatee address of the delegate escrowed tokens votes to (if address(0) then it defaults to the beneficiary)
    /// @param _start start time of the vesting period
    /// @param _cliffDuration duration before which first tokens gets ownable
    /// @param _duration duration of the entire vesting (sum of all vesting period durations)
    /// @param _periodDuration duration of a single period of vesting
    /// @param _lockDuration duration before tokens gets unlocked. can exceed the duration of the vesting chedule
    /// @param _revocable whether the schedule can be revoked
    /// @param _amount amount of tokens granted by the vesting schedule
    /// @return index of the created vesting schedule
    function _createVestingSchedule(
        address _creator,
        address _beneficiary,
        address _delegatee,
        uint64 _start,
        uint32 _cliffDuration,
        uint32 _duration,
        uint32 _periodDuration,
        uint32 _lockDuration,
        bool _revocable,
        uint256 _amount
    ) internal returns (uint256) {
        if (balanceOf(_creator) < _amount) {
            revert UnsufficientVestingScheduleCreatorBalance();
        }

        // validate schedule parameters
        if (_beneficiary == address(0)) {
            revert InvalidVestingScheduleParameter("Vesting schedule beneficiary must be non zero address");
        }

        if (_duration == 0) {
            revert InvalidVestingScheduleParameter("Vesting schedule duration must be > 0");
        }

        if (_amount == 0) {
            revert InvalidVestingScheduleParameter("Vesting schedule amount must be > 0");
        }

        if (_periodDuration == 0) {
            revert InvalidVestingScheduleParameter("Vesting schedule period must be > 0");
        }

        if (_duration % _periodDuration > 0) {
            revert InvalidVestingScheduleParameter("Vesting schedule duration must split in exact periods");
        }

        if (_cliffDuration % _periodDuration > 0) {
            revert InvalidVestingScheduleParameter("Vesting schedule cliff duration must split in exact periods");
        }

        if (_cliffDuration > _duration) {
            revert InvalidVestingScheduleParameter(
                "Vesting schedule duration must be greater than or equal to the cliff duration"
            );
        }

        if ((_amount * _periodDuration) / _duration == 0) {
            revert InvalidVestingScheduleParameter("Vesting schedule amount too low for duration and period");
        }

        // if input start time is 0 then default to the current block time
        if (_start == 0) {
            _start = uint64(block.timestamp);
        }

        // create new vesting schedule
        VestingSchedulesV2.VestingSchedule memory vestingSchedule = VestingSchedulesV2.VestingSchedule({
            start: _start,
            end: _start + _duration,
            lockDuration: _lockDuration,
            cliffDuration: _cliffDuration,
            duration: _duration,
            periodDuration: _periodDuration,
            amount: _amount,
            creator: _creator,
            beneficiary: _beneficiary,
            revocable: _revocable,
            releasedAmount: 0
        });
        uint256 index = VestingSchedulesV2.push(vestingSchedule) - 1;

        // compute escrow address that will hold the token during the vesting
        address escrow = _deterministicVestingEscrow(index);

        // transfer tokens to the escrow
        _transfer(_creator, escrow, _amount);

        // delegate escrow tokens
        if (_delegatee == address(0)) {
            // default delegatee to beneficiary address
            _delegate(escrow, _beneficiary);
        } else {
            _delegate(escrow, _delegatee);
        }

        emit CreatedVestingSchedule(index, _creator, _beneficiary, _amount);

        return index;
    }

    /// @notice Revoke vesting schedule
    /// @param _index Index of the vesting schedule to revoke
    /// @param _end End date for the schedule
    /// @return returnedAmount amount returned to the vesting schedule creator
    function _revokeVestingSchedule(uint256 _index, uint64 _end) internal returns (uint256) {
        if (_end == 0) {
            // if end time is 0 then default to current block time
            _end = uint64(block.timestamp);
        } else if (_end < block.timestamp) {
            revert VestingScheduleNotRevocableInPast();
        }

        VestingSchedulesV2.VestingSchedule storage vestingSchedule = VestingSchedulesV2.get(_index);
        if (!vestingSchedule.revocable) {
            revert VestingScheduleNotRevocable();
        }

        // revoked end date MUST be after vesting schedule start and before current end
        if ((_end < vestingSchedule.start) || (vestingSchedule.end < _end)) {
            revert InvalidRevokedVestingScheduleEnd();
        }

        // only creator can revoke vesting schedule
        if (vestingSchedule.creator != msg.sender) {
            revert LibErrors.Unauthorized(msg.sender);
        }

        // return tokens that will never be vested to creator
        uint256 vestedAmountAtOldEnd = _computeVestedAmount(vestingSchedule, vestingSchedule.end);
        uint256 vestedAmountAtNewEnd = _computeVestedAmount(vestingSchedule, _end);
        uint256 returnedAmount = vestedAmountAtOldEnd - vestedAmountAtNewEnd;
        if (returnedAmount > 0) {
            address escrow = _deterministicVestingEscrow(_index);
            _transfer(escrow, vestingSchedule.creator, returnedAmount);
        }

        // set schedule end
        vestingSchedule.end = uint64(_end);

        emit RevokedVestingSchedule(_index, returnedAmount, _end);

        return returnedAmount;
    }

    /// @notice Release vesting schedule
    /// @param _index Index of the vesting schedule to release
    /// @return released amount
    function _releaseVestingSchedule(uint256 _index) internal returns (uint256) {
        VestingSchedulesV2.VestingSchedule storage vestingSchedule = VestingSchedulesV2.get(_index);

        // only beneficiary can release
        if (msg.sender != vestingSchedule.beneficiary) {
            revert LibErrors.Unauthorized(msg.sender);
        }

        uint256 time = _getCurrentTime();
        if (time < (vestingSchedule.start + vestingSchedule.lockDuration)) {
            // before lock no tokens can be vested
            revert VestingScheduleIsLocked();
        }

        // compute releasable amount
        uint256 releasableAmount = _computeVestingReleasableAmount(vestingSchedule, time);
        if (releasableAmount == 0) {
            revert ZeroReleasableAmount();
        }

        address escrow = _deterministicVestingEscrow(_index);

        // transfer all releasable token to the beneficiary
        _transfer(escrow, vestingSchedule.beneficiary, releasableAmount);

        // increase released amount as per the release
        vestingSchedule.releasedAmount += releasableAmount;

        emit ReleasedVestingSchedule(_index, releasableAmount);

        return releasableAmount;
    }

    /// @notice Delegate vesting escrowed tokens
    /// @param _index index of the vesting schedule
    /// @param _delegatee address to delegate the token to
    /// @return True on success
    function _delegateVestingEscrow(uint256 _index, address _delegatee) internal returns (bool) {
        VestingSchedulesV2.VestingSchedule storage vestingSchedule = VestingSchedulesV2.get(_index);

        // only beneficiary can delegate
        if (msg.sender != vestingSchedule.beneficiary) {
            revert LibErrors.Unauthorized(msg.sender);
        }

        // update delegatee
        address escrow = _deterministicVestingEscrow(_index);
        address oldDelegatee = delegates(escrow);
        _delegate(escrow, _delegatee);

        emit DelegatedVestingEscrow(_index, oldDelegatee, _delegatee, vestingSchedule.beneficiary);

        return true;
    }

    /// @notice Internal utility to compute the unique escrow deterministic address
    /// @param _index index of the vesting schedule
    /// @return escrow The deterministic escrow address for the vesting schedule index
    function _deterministicVestingEscrow(uint256 _index) internal view returns (address escrow) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), ESCROW, _index));
        return address(uint160(uint256(hash)));
    }

    /// @notice Computes the releasable amount of tokens for a vesting schedule.
    /// @param _vestingSchedule vesting schedule to compute releasable tokens for
    /// @param _time time to compute the releasable amount at
    /// @return amount of release tokens
    function _computeVestingReleasableAmount(VestingSchedulesV2.VestingSchedule memory _vestingSchedule, uint256 _time)
        internal
        pure
        returns (uint256)
    {
        uint256 releasedAmount = _vestingSchedule.releasedAmount;

        if (_time > _vestingSchedule.end) {
            _time = _vestingSchedule.end;
        }

        uint256 vestedAmount = _computeVestedAmount(_vestingSchedule, _time);
        if (vestedAmount > releasedAmount) {
            unchecked {
                return vestedAmount - releasedAmount;
            }
        }

        return 0;
    }

    /// @notice Computes the vested amount of tokens for a vesting schedule.
    /// @param _vestingSchedule vesting schedule to compute vested tokens for
    /// @param _time time to compute the vested amount at
    /// @return amount of release tokens
    function _computeVestedAmount(VestingSchedulesV2.VestingSchedule memory _vestingSchedule, uint256 _time)
        internal
        pure
        returns (uint256)
    {
        if (_time < _vestingSchedule.start + _vestingSchedule.cliffDuration) {
            // pre-cliff no tokens have been vested
            return 0;
        } else if (_time >= _vestingSchedule.start + _vestingSchedule.duration) {
            // post vesting all tokens have been vested
            return _vestingSchedule.amount;
        } else {
            uint256 timeFromStart = _time - _vestingSchedule.start;

            // compute tokens vested for completly elapsed periods
            uint256 vestedDuration = timeFromStart - timeFromStart % _vestingSchedule.periodDuration;

            return (vestedDuration * _vestingSchedule.amount) / _vestingSchedule.duration;
        }
    }

    /// @notice Returns current time
    /// @return The current time
    function _getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}