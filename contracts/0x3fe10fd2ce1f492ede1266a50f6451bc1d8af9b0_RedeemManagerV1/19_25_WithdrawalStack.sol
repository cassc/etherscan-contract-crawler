//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Redeem Manager Withdrawal Stack storage
/// @notice Utility to manage the Withdrawal Stack in the Redeem Manager
library WithdrawalStack {
    /// @notice Storage slot of the Withdrawal Stack
    bytes32 internal constant WITHDRAWAL_STACK_ID_SLOT = bytes32(uint256(keccak256("river.state.withdrawalStack")) - 1);

    /// @notice The Redeemer structure represents the withdrawal events made by River
    struct WithdrawalEvent {
        /// @custom:attribute The amount of the withdrawal event in LsETH
        uint256 amount;
        /// @custom:attribute The amount of the withdrawal event in ETH
        uint256 withdrawnEth;
        /// @custom:attribute The height is the cumulative sum of all the sizes of preceding withdrawal events
        uint256 height;
    }

    /// @notice Retrieve the Withdrawal Stack array storage pointer
    /// @return data The Withdrawal Stack array storage pointer
    function get() internal pure returns (WithdrawalEvent[] storage data) {
        bytes32 position = WITHDRAWAL_STACK_ID_SLOT;
        assembly {
            data.slot := position
        }
    }
}