// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Clone} from "clones-with-immutable-args/Clone.sol";

/**
 * @notice helpers for the immutable args
 * stored by ChunkedVestingVault
 */
contract ChunkedVestingVaultArgs is Clone {
    /**
     * @notice The token which is being vested
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return the token which is being vested
     */
    function vestingPeriods() public pure returns (uint256) {
        // starts at 40 because of the parent VestingVault uses bytes 0-39 for token and beneficiary
        return _getArgUint256(40);
    }

    /**
     * @notice The array of chunked amounts to be vested
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return the array of chunked amounts to be vested
     */
    function amounts() public pure returns (uint256[] memory) {
        return _getArgUint256Array(72, uint64(vestingPeriods()));
    }

    /**
     * @notice The array of timestamps at which chunks of tokens are vested
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @dev These are expected to be already sorted in timestamp order
     * @return the timestamps at which chunks of tokens are vested
     */
    function timestamps() public pure returns (uint256[] memory) {
        return _getArgUint256Array(
            72 + (32 * vestingPeriods()), uint64(vestingPeriods())
        );
    }

    /**
     * @notice The amount to be vested at the given index
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return the amount to be vested at the given index
     */
    function amountAtIndex(uint256 index) public pure returns (uint256) {
        return _getArgUint256(72 + (32 * index));
    }

    /**
     * @notice The timestamp at which the given index chunk is vested
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return the timestamp at which the given index chunk is vested
     */
    function timestampAtIndex(uint256 index) public pure returns (uint256) {
        return _getArgUint256(72 + (32 * vestingPeriods()) + (32 * index));
    }
}