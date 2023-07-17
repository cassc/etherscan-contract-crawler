// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract FeeApproverLike {
    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        virtual
        returns (
            uint256 transferToAmount,
            uint256 transferToFeeDistributorAmount
        );
}