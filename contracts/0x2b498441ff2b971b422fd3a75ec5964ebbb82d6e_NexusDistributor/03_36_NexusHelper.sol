// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

library NexusHelper {
    event ClaimPayoutRedeemed(
        uint256 indexed coverId,
        uint256 indexed claimId,
        address indexed receiver,
        uint256 amountPaid,
        address coverAsset
    );

    event ClaimSubmitted(
        uint256 indexed coverId,
        uint256 indexed claimId,
        address indexed submitter
    );
}