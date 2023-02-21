// SPDX-License-Identifier: None
// Unvest Contracts (last updated v2.0.0) (interfaces/IFeeManager.sol)
pragma solidity 0.8.17;

/**
 * @title IFeeManager
 * @dev Interface that describes the struct and accessor function for the data related to the collection of fees.
 */
interface IFeeManager {
    /**
     * @dev `feeCollector` is the address that will collect the fees of every transaction of `VestingToken`s
     * @dev `feePercentage` is the percentage of every transaction that will be collected.
     */
    struct FeeData {
        address feeCollector;
        uint64 feePercentage;
    }

    /**
     * @notice Exposes the `FeeData` for `VestingToken`s to consume.
     */
    function feeData() external view returns (FeeData memory);
}