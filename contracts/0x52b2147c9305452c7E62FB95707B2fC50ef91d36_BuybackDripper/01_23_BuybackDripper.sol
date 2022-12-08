// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IBuybackDripper.sol";
import "./libraries/ErrorCodes.sol";
import "./interfaces/IMnt.sol";

/// @title Buyback drip Contract
/// @notice Distributes a token to a buyback at a fixed rate.
/// @dev This contract must be poked via the `drip()` function every so often.
/// @author Minterest
contract BuybackDripper is IBuybackDripper, AccessControl {
    using SafeERC20Upgradeable for IMnt;

    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    /// @dev Value is the Keccak-256 hash of "TOKEN_PROVIDER"
    bytes32 public constant TOKEN_PROVIDER =
        bytes32(0x8c60700f65fcee73179f64477eb1484ea199744913cfa6e5fe87df1dcd47e13d);

    uint256 private constant RATE_SCALE = 1e18;

    IBuyback public immutable buyback;
    IMnt public immutable mnt;

    /// @notice Duration in hours that will be used at next period start
    /// @dev 168 is the average amount of hours in a week
    uint256 public nextPeriodDuration = 168;

    /// @notice Drip rate that will be used at next period start
    uint256 public nextPeriodRate = 1e18;

    /// @notice Timestamp in hours of current period start
    uint256 public periodStart;

    /// @notice Duration in hours of current period
    uint256 public periodDuration;

    /// @notice Tokens that should go to buyback per hour during current period
    uint256 public dripPerHour;

    /// @notice Timestamp in hours when last drip to buyback occurred
    uint256 public previousDripTime;

    /// @dev Amount of tokens available for drip
    uint256 public dripBalance;

    /// @notice Constructs a BuybackDripper
    /// @param buyback_ The target Buyback contract
    /// @param mnt_ The Minterest token contract
    /// @param admin_ The address of DEFAULT_ADMIN_ROLE and TIMELOCK
    constructor(
        IBuyback buyback_,
        IMnt mnt_,
        address admin_
    ) {
        buyback = buyback_;
        mnt = mnt_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TOKEN_PROVIDER, admin_);
        _grantRole(TIMELOCK, admin_);
        require(mnt.approve(address(buyback_), type(uint256).max), ErrorCodes.MNT_APPROVE_FAILS);
    }

    /// @inheritdoc IBuybackDripper
    function setPeriodDuration(uint256 duration) external onlyRole(TIMELOCK) {
        require(duration > 0, ErrorCodes.INVALID_DURATION);
        nextPeriodDuration = duration;
        emit PeriodDurationChanged(duration);
    }

    /// @inheritdoc IBuybackDripper
    function setPeriodRate(uint256 rate) external onlyRole(TIMELOCK) {
        require(rate > 0 && rate <= 1e18, ErrorCodes.INVALID_PERIOD_RATE);
        nextPeriodRate = rate;
        emit PeriodRateChanged(rate);
    }

    /// @inheritdoc IBuybackDripper
    function drip() external {
        uint256 timeUnits = getTime();
        uint256 timeSinceDrip = timeUnits - previousDripTime;
        require(timeSinceDrip > 0, ErrorCodes.TOO_EARLY_TO_DRIP);

        // Reset period if last drip was older than period duration
        if (timeSinceDrip >= periodDuration) {
            previousDripTime = timeUnits;
            resetPeriod(timeUnits);
            return;
        }

        uint256 nextPeriodStart = periodStart + periodDuration;

        uint256 dripUntil = Math.min(timeUnits, nextPeriodStart);
        uint256 dripDuration = dripUntil - previousDripTime;
        uint256 toDrip = dripDuration * dripPerHour;
        previousDripTime = dripUntil;

        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
        buyback.buyback(toDrip);
        dripBalance -= toDrip;

        if (dripUntil >= nextPeriodStart) {
            resetPeriod(nextPeriodStart);
        }
    }

    /// @inheritdoc IBuybackDripper
    function refill(uint256 amount) external onlyRole(TOKEN_PROVIDER) {
        require(amount > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
        dripBalance += amount;
        mnt.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @dev Starts new Period with pending parameters
    /// @param newStart timestamp of new period start
    function resetPeriod(uint256 newStart) private {
        uint256 newDripPerHour = (dripBalance * nextPeriodRate) / RATE_SCALE / nextPeriodDuration;
        periodStart = newStart;
        periodDuration = nextPeriodDuration;
        dripPerHour = newDripPerHour;

        emit NewPeriod(newStart, nextPeriodDuration, newDripPerHour);
    }

    /// @return timestamp truncated to hours
    function getTime() private view returns (uint256) {
        return block.timestamp / 1 hours;
    }
}