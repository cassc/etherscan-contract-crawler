// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

library LibPublicSale {
    struct UserInfoEx {
        bool join;
        uint tier;
        uint256 payAmount;
        uint256 saleAmount;
    }

    struct UserInfoOpen {
        bool join;
        uint256 depositAmount;
        uint256 payAmount;
    }

    struct UserClaim {
        bool exec;
        uint256 claimAmount;
        uint256 refundAmount;
    }
}