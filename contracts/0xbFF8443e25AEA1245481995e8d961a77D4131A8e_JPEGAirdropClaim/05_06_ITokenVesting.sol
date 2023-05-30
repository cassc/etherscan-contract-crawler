// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface ITokenVesting  {
    /// @notice Allows members of `VESTING_CONTROLLER_ROLE` to vest tokens
    /// @dev Emits a {NewBeneficiary} event
    /// @param beneficiary The beneficiary of the tokens
    /// @param totalAllocation The total amount of tokens allocated to `beneficiary`
    /// @param start The start timestamp
    /// @param cliffDuration The duration of the cliff period (can be 0)
    /// @param duration The duration of the vesting period (starting from `start`)
    function vestTokens(
        address beneficiary,
        uint256 totalAllocation,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration
    ) external;

    function token() external view returns (address);
}