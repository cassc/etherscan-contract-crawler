// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ITokenVesting} from "./interfaces/ITokenVesting.sol";
import {VestingSchedule} from "./defs/VestingSchedule.sol";
import {VestingScheduleConfig} from "./defs/VestingScheduleConfig.sol";

contract TokenVesting is ITokenVesting, Owned, ReentrancyGuard {
    //
    // - STORAGE -
    //
    ERC20 private immutable _token;

    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;

    //
    // - CONSTRUCTOR -
    //
    /**
     * @dev Creates a vesting contract.
     * @param token_ address of the ERC20 token contract
     */
    constructor(address token_) Owned(msg.sender) {
        require(token_ != address(0x0));
        _token = ERC20(token_);
    }

    //
    // - MUTATORS (ADMIN) -
    //
    function createVestingSchedule(
        address beneficiary_,
        uint64 start_,
        uint64 cliff_,
        uint64 duration_,
        uint64 slicePeriodSeconds_,
        uint256 amount_,
        bool revocable_
    ) external {
        _onlyOwner();
        _createVestingSchedule(
            VestingScheduleConfig({
                beneficiary: beneficiary_,
                start: start_,
                cliff: cliff_,
                duration: duration_,
                slicePeriodSeconds: slicePeriodSeconds_,
                amountTotal: amount_,
                revocable: revocable_
            })
        );
    }

    function revoke(bytes32 vestingScheduleId) external {
        _onlyOwner();
        _vestingScheduleNotRevoked(vestingScheduleId);
        _vestingScheduleRevocable(vestingScheduleId);

        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        
        uint256 unreleased = vestingSchedule.amountTotal - vestingSchedule.released;
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - unreleased;
        vestingSchedule.revoked = true;
        emit VestingScheduleCancelled(vestingScheduleId);
    }

    function extend(bytes32 vestingScheduleId, uint32 extensionDuration) external {
        _onlyOwner();
        _vestingScheduleNotRevoked(vestingScheduleId);
        _vestingScheduleNotExpired(vestingScheduleId);
        _vestingScheduleRevocable(vestingScheduleId);
        require(extensionDuration > 0, "Zero Duration");

        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        vestingSchedule.duration += extensionDuration;
        emit VestingScheduleExtended(vestingScheduleId, extensionDuration);
    }

    function withdraw(uint256 amount) external nonReentrant {
        _onlyOwner();
        require(getWithdrawableAmount() >= amount, "Insufficient Token Balance");
        emit AmountWithdrawn(amount);
        SafeTransferLib.safeTransfer(_token, msg.sender, amount);
    }

    //
    // - MUTATORS -
    //
    function release(bytes32 vestingScheduleId, uint256 amount) public nonReentrant {
        _vestingScheduleNotRevoked(vestingScheduleId);
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        _onlyOwnerOrBeneficiary(vestingSchedule);

        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount >= amount, "Insufficient Vested Balance");
        vestingSchedule.released = vestingSchedule.released + amount;
        address payable beneficiaryPayable = payable(vestingSchedule.beneficiary);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - amount;
        emit AmountReleased(vestingScheduleId, vestingSchedule.beneficiary, amount);
        SafeTransferLib.safeTransfer(_token, beneficiaryPayable, amount);
    }

    //
    // - VIEW -
    //
    function getVestingSchedulesCountByBeneficiary(
        address _beneficiary
    ) external view returns (uint256) {
        return holdersVestingCount[_beneficiary];
    }

    function getVestingIdAtIndex(uint256 index) external view returns (bytes32) {
        require(index < getVestingSchedulesCount(), "Index Out of Bounds");
        return vestingSchedulesIds[index];
    }

    function getVestingScheduleByAddressAndIndex(
        address holder,
        uint256 index
    ) external view returns (VestingSchedule memory) {
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(holder, index));
    }

    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    function getToken() external view returns (address) {
        return address(_token);
    }

    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedulesIds.length;
    }

    function computeReleasableAmount(bytes32 vestingScheduleId) external view returns (uint256) {
        _vestingScheduleNotRevoked(vestingScheduleId);
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        return _computeReleasableAmount(vestingSchedule);
    }

    function getVestingSchedule(
        bytes32 vestingScheduleId
    ) public view returns (VestingSchedule memory) {
        return vestingSchedules[vestingScheduleId];
    }

    function getWithdrawableAmount() public view returns (uint256) {
        return _token.balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }

    function computeNextVestingScheduleIdForHolder(address holder) public view returns (bytes32) {
        return computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder]);
    }

    function getLastVestingScheduleForHolder(
        address holder
    ) external view returns (VestingSchedule memory) {
        return
            vestingSchedules[
                computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder] - 1)
            ];
    }

    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    //
    // - INTERNALS -
    //
    function _createVestingSchedule(VestingScheduleConfig memory config) internal {
        require(config.beneficiary != address(0), "Zero Beneficiary Address");
        require(getWithdrawableAmount() >= config.amountTotal, "Insufficient Token Balance");
        require(config.duration > 0, "Zero Duration");
        require(config.amountTotal > 0, "Zero Amount");
        require(config.slicePeriodSeconds >= 1, "Zero Slice Period");
        require(config.duration >= config.cliff, "Cliff Exceeds Duration");
        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(config.beneficiary);

        vestingSchedules[vestingScheduleId] = VestingSchedule({
            initialized: true,
            beneficiary: config.beneficiary,
            cliff: config.start + config.cliff,
            start: config.start,
            duration: config.duration,
            slicePeriodSeconds: config.slicePeriodSeconds,
            amountTotal: config.amountTotal,
            released: 0,
            revoked: false,
            revocable: config.revocable
        });
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount + config.amountTotal;
        vestingSchedulesIds.push(vestingScheduleId);
        holdersVestingCount[config.beneficiary]++;

        emit VestingScheduleCreated(vestingScheduleId, config.beneficiary, config.amountTotal);
    }

    function _computeReleasableAmount(
        VestingSchedule memory vestingSchedule
    ) internal view returns (uint256) {
        // Retrieve the current time.
        uint256 currentTime = block.timestamp;
        // If the current time is before the cliff, no tokens are releasable.
        if ((currentTime < vestingSchedule.cliff) || vestingSchedule.revoked) {
            return 0;
        }
        // If the current time is after the vesting period, all tokens are releasable,
        // minus the amount already released.
        else if (currentTime >= vestingSchedule.start + vestingSchedule.duration) {
            return vestingSchedule.amountTotal - vestingSchedule.released;
        }
        // Otherwise, some tokens are releasable.
        else {
            // Compute the number of full vesting periods that have elapsed.
            uint256 timeFromStart = currentTime - vestingSchedule.start;
            uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
            uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
            // Compute the amount of tokens that are vested.
            uint256 vestedAmount = (vestingSchedule.amountTotal * vestedSeconds) /
                vestingSchedule.duration;
            // Subtract the amount already released and return.
            return vestedAmount - vestingSchedule.released;
        }
    }

    /**
     * @dev Reverts if the caller is not the contract owner.
     */
    function _onlyOwner() internal view {
        require(msg.sender == owner, "UNAUTHORIZED");
    }

    /**
     * @dev Reverts if the caller is neither the contract owner nor the vesting schedule beneficiary.
     */
    function _onlyOwnerOrBeneficiary(VestingSchedule storage vestingSchedule) internal view {
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isReleasor = (msg.sender == owner);

        require(isBeneficiary || isReleasor, "Not Beneficiary or Releasor");
    }

    /**
     * @dev Reverts if the vesting schedule does not exist or has been revoked.
     */
    function _vestingScheduleNotRevoked(bytes32 vestingScheduleId) internal view {
        require(vestingSchedules[vestingScheduleId].initialized, "Vesting Schedule Not Found");
        require(!vestingSchedules[vestingScheduleId].revoked, "Vesting Schedule Revoked");
    }

    function _vestingScheduleNotExpired(bytes32 vestingScheduleId) internal view {
        require(
            vestingSchedules[vestingScheduleId].start +
                vestingSchedules[vestingScheduleId].duration >
                block.timestamp,
            "Vesting Schedule Expired"
        );
    }

    function _vestingScheduleRevocable(bytes32 vestingScheduleId) internal view {
        require(vestingSchedules[vestingScheduleId].revocable, "Vesting Schedule Not Revocable");
    }
}