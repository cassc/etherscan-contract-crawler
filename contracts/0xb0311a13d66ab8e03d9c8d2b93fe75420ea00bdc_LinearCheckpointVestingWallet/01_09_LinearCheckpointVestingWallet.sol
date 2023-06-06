// SPDX-License-Identifier: UNLICENSED
import "../openzeppelin-contracts/contracts/finance/VestingWallet.sol";
import "./LinearCheckpointVesting.sol";
pragma solidity 0.8.5;

/**
 * @title LinearCheckpointVestingWallet
 *
 * @dev Implements a vesting wallet that releases "chunks" of the vested amount linearly according to some defined
 *  checkpoints.
 */
contract LinearCheckpointVestingWallet is LinearCheckpointVesting, VestingWallet  {

    /**
     * @dev Calls the {VestingWallet} {LinearCheckpointVesting} constructors
     * @param beneficiaryAddress The address that will be allowed to release tokens from this
     *  contract
     * @param checkpoints @inheritdoc
     */
    constructor(
        address beneficiaryAddress,
        uint64[] memory checkpoints
    ) VestingWallet(beneficiaryAddress, checkpoints[0], checkpoints[checkpoints.length - 1] - checkpoints[0])
        LinearCheckpointVesting(checkpoints) {}

    /**
     * @dev Delegates to the {CheckpointVesting} implementation
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) override internal view returns (uint256) {
        return LinearCheckpointVesting.checkpointVestingSchedule(totalAllocation, timestamp);
     }
}