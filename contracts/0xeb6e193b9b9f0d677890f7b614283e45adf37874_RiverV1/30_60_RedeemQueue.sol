//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Redeem Manager Redeem Queue storage
/// @notice Utility to manage the Redeem Queue in the Redeem Manager
library RedeemQueue {
    /// @notice Storage slot of the Redeem Queue
    bytes32 internal constant REDEEM_QUEUE_ID_SLOT = bytes32(uint256(keccak256("river.state.redeemQueue")) - 1);

    /// @notice The Redeemer structure represents the redeem request made by a user
    struct RedeemRequest {
        /// @custom:attribute The amount of the redeem request in LsETH
        uint256 amount;
        /// @custom:attribute The maximum amount of ETH redeemable by this request
        uint256 maxRedeemableEth;
        /// @custom:attribute The owner of the redeem request
        address owner;
        /// @custom:attribute The height is the cumulative sum of all the sizes of preceding redeem requests
        uint256 height;
    }

    /// @notice Retrieve the Redeem Queue array storage pointer
    /// @return data The Redeem Queue array storage pointer
    function get() internal pure returns (RedeemRequest[] storage data) {
        bytes32 position = REDEEM_QUEUE_ID_SLOT;
        assembly {
            data.slot := position
        }
    }
}