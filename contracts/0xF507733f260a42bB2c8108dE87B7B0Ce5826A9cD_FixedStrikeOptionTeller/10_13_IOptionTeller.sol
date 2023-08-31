// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IOptionTeller {
    /// @notice         Set minimum duration to exercise option
    /// @notice         Access controlled
    /// @dev            Absolute minimum is 1 day (86400 seconds) due to timestamp rounding of eligible and expiry parameters
    /// @param duration_ Minimum duration in seconds
    function setMinOptionDuration(uint48 duration_) external;

    /// @notice         Set protocol fee
    /// @notice         Access controlled
    /// @param fee_     Protocol fee in basis points (3 decimal places)
    function setProtocolFee(uint48 fee_) external;

    /// @notice         Claim fees accrued by protocol in the input tokens and sends them to the provided address
    /// @notice         Access controlled
    /// @param tokens_  Array of tokens to claim fees for
    /// @param to_      Address to send fees to
    function claimFees(ERC20[] memory tokens_, address to_) external;

    /// @notice         Minimum duration an option must be eligible for exercise for (in seconds)
    function minOptionDuration() external view returns (uint48);
}