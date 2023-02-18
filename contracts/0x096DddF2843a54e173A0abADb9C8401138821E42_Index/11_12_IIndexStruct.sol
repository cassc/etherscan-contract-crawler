//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IndexStruct {
    struct feeData {
        address managementFeeAddress;
        address performanceFeeAddress;
        uint256 managementFeeBasisPoint;
        uint256 performanceFeeBasisPoint;
    }
    ///structure for the index state
    struct State {
        bool purchased;
        bool updated;
        bool soldprevafterupdate;
        bool staked;
        bool unstaked;
        bool rewardtokensold;
        bool sold;
        bool performancefeestransfer;
    }

    struct Depositor {
        uint amount;
        bool status;
    }
}