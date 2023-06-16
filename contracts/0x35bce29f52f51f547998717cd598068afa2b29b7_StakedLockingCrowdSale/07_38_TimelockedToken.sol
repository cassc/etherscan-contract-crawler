// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

struct Schedule {
    uint64 expiresAt;
    address beneficiary;
    uint256 amount;
}

error NotSupported();
error ScheduleOutOfRange();
error StillLocked();
error DuplicateSchedule();

/**
 * @title TimelockedToken
 * @author molecule.to
 * @notice wraps & locks an underlying ERC20 token for a scheduled amount of time
 * @dev we were considering EIP-1132 but use a far more reduced interface that requires tracing due unlocking schedules off chain
 */
contract TimelockedToken is IERC20MetadataUpgradeable, Initializable {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public underlyingToken;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(bytes32 => Schedule) public schedules;

    event ScheduleCreated(bytes32 indexed scheduleId, address indexed beneficiary, address indexed creator, uint256 amount, uint64 expiresAt);
    event ScheduleReleased(bytes32 indexed scheduleId, address indexed beneficiary, uint256 amount);

    function initialize(IERC20Metadata underlyingToken_) external initializer {
        underlyingToken = underlyingToken_;
    }

    /**
     * @inheritdoc IERC20MetadataUpgradeable
     */
    function name() external view returns (string memory) {
        return string.concat("Locked ", underlyingToken.name());
    }

    /**
     * @inheritdoc IERC20MetadataUpgradeable
     */
    function symbol() external view returns (string memory) {
        return string.concat("l", underlyingToken.symbol());
    }

    /**
     * @inheritdoc IERC20MetadataUpgradeable
     */
    function decimals() external view returns (uint8) {
        return underlyingToken.decimals();
    }
    /**
     * @inheritdoc IERC20Upgradeable
     */

    function transfer(address, uint256) external pure returns (bool) {
        revert NotSupported();
    }

    /**
     * @inheritdoc IERC20Upgradeable
     */
    function approve(address, uint256) external pure returns (bool) {
        revert NotSupported();
    }

    /**
     * @inheritdoc IERC20Upgradeable
     */
    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert NotSupported();
    }

    /**
     * @inheritdoc IERC20Upgradeable
     */
    function allowance(address, address) external pure returns (uint256) {
        return 0;
    }

    /**
     * @inheritdoc IERC20Upgradeable
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice lock `amount` tokens for `beneficiary` to withdraw until `expiresAt`
     * @param beneficiary the account that will be able to unlock `amount` after `expiresAt`
     * @param amount the amount to be locked
     * @param expiresAt the timestamp when `amount` should become unlockable
     * @return scheduleId the schedule's id. Must be tracked off chain
     */
    function lock(address beneficiary, uint256 amount, uint64 expiresAt) external returns (bytes32 scheduleId) {
        if (expiresAt < block.timestamp + 15 minutes || expiresAt > block.timestamp + 5 * 365 days) {
            revert ScheduleOutOfRange();
        }

        scheduleId = keccak256(abi.encodePacked(msg.sender, beneficiary, amount, expiresAt));
        if (schedules[scheduleId].beneficiary != address(0)) {
            revert DuplicateSchedule();
        }

        schedules[scheduleId] = Schedule(expiresAt, beneficiary, amount);
        balances[beneficiary] += amount;
        totalSupply += amount;
        emit ScheduleCreated(scheduleId, beneficiary, msg.sender, amount, expiresAt);

        underlyingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice releases the amount tracked by schedule `scheduleId` if schedule's date has expired
     * @param scheduleId the schedule's id
     */
    function release(bytes32 scheduleId) public {
        Schedule memory schedule = schedules[scheduleId];
        if (schedule.expiresAt > block.timestamp) {
            revert StillLocked();
        }
        totalSupply -= schedule.amount;
        balances[schedule.beneficiary] -= schedule.amount;
        emit ScheduleReleased(scheduleId, schedule.beneficiary, schedule.amount);
        delete schedules[scheduleId];

        underlyingToken.safeTransfer(schedule.beneficiary, schedule.amount);
    }

    /**
     * @notice releases many schedules at once, reverts when any of them is invalid
     * @param scheduleIds the schedule ids to release
     */
    function releaseMany(bytes32[] calldata scheduleIds) external {
        for (uint256 i = 0; i < scheduleIds.length; i++) {
            release(scheduleIds[i]);
        }
    }
}