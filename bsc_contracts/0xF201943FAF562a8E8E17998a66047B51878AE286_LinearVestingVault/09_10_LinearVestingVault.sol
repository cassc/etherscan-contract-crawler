// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {VestingVault} from "./VestingVault.sol";

/**
 * @notice VestingVault contract for a linear release of tokens after a period of time
 * @dev immutable args:
 * - slot 0 - address token (20 bytes) (in VestingVault)
 * - slot 1 - address beneficiary (20 bytes) (in VestingVault)
 * - slot 2 - uint256 vestStartTimestamp
 * - slot 3 - uint256 vestEndTimestamp
 * - slot 4 - uint256 totalAmount
 */
contract LinearVestingVault is VestingVault {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice The timestamp at which the vesting begins
     * @dev using ClonesWithImmutableArgs pattern here to save ga s
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return the timestamp at which the vesting begins
     */
    function vestStartTimestamp() public pure returns (uint256) {
        // starts at 40 because of the parent VestingVault uses bytes 0-39 for token and beneficiary
        return _getArgUint256(40);
    }

    /**
     * @notice The timestamp at which the vesting ends
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The timestamp at which the vesting ends
     */
    function vestEndTimestamp() public pure returns (uint256) {
        return _getArgUint256(72);
    }

    /**
     * @notice The total number of tokens to be vested
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The total number of tokens to be vested
     */
    function totalAmount() public pure returns (uint256) {
        return _getArgUint256(104);
    }

    /// @notice The amount of tokens claimed so far
    uint256 public amountClaimed;

    /**
     * @notice Initializes the vesting vault
     * @dev this pulls in the required ERC20 tokens from the sender to setup
     */
    function initialize() public initializer {
        if (vestStartTimestamp() > vestEndTimestamp()) {
            revert InvalidParams();
        }
        VestingVault.initialize(totalAmount());
    }

    /**
     * @inheritdoc VestingVault
     */
    function vestedOn(uint256 timestamp)
        public
        view
        override
        returns (uint256 amount)
    {
        // total amount multipled by the proportion of vesting period that has passed
        uint256 totalVested = (
            totalAmount() * (timestamp - vestStartTimestamp())
        ) / (vestEndTimestamp() - vestStartTimestamp());
        if (totalVested > totalAmount()) {
            totalVested = totalAmount();
        }
        return totalVested - amountClaimed;
    }

    /**
     * @inheritdoc VestingVault
     */
    function onClaim(uint256 amount) internal override {
        amountClaimed += amount;
    }
}