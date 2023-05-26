// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./../PreJPEG.sol";

/// @title JPEGAirdrop
/// @notice {JPEG} airdrop vesting contract, beneficiaries get aJPEG, which can be burned linearly to unlock {JPEG}.
/// {aJPEG} cannot be transferred.
/// @dev This contract has the same use and shares the same logic as {PreJPEG}, with the only difference being that
/// vesting schedules can start at a timestamp that's less than the current one.
/// This is needed as every airdrop recipient will have the same vesting schedule no matter when they claim their aJPEG.
contract JPEGAirdrop is PreJPEG {
    using SafeERC20 for IERC20;

    /// @param _jpeg The token to vest
    constructor(address _jpeg)
        PreJPEG(_jpeg)
    {}

    /// @inheritdoc ERC20
    /// @dev This function is overridden since {PreJPEG} has its name
    /// hardcoded in the constructor
    function name() public pure override returns (string memory) {
        return "airdropJPEG";
    }

    /// @inheritdoc ERC20
    /// @dev This function is overridden since {PreJPEG} has its symbol
    /// hardcoded in the constructor
    function symbol() public pure override returns (string memory) {
        return "aJPEG";
    }

    /// @inheritdoc TokenVesting
    /// @notice Beneficiaries get an amount of {aJPEG} equal to `totalAllocation`
    /// @dev This function works the same as `TokenVesting.vestTokens` with the only difference being that
    /// `start` can be less than `block.timestamp`.
    function vestTokens(
        address beneficiary,
        uint256 totalAllocation,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration
    ) public virtual override onlyRole(VESTING_CONTROLLER_ROLE) {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(
            vestingSchedules[beneficiary].totalAllocation == 0,
            "Beneficiary already exists"
        );
        require(totalAllocation > 0, "Invalid allocation");
        require(start > 0, "Invalid start");
        require(duration > 0, "Invalid duration");
        require(duration > cliffDuration, "Invalid cliff");

        vestingSchedules[beneficiary] = VestingSchedule({
            totalAllocation: totalAllocation,
            start: start,
            cliffDuration: cliffDuration,
            duration: duration,
            released: 0
        });

        token.safeTransferFrom(msg.sender, address(this), totalAllocation);

        _mint(beneficiary, totalAllocation);

        emit NewBeneficiary(beneficiary, totalAllocation, start, cliffDuration, duration);
    }

}