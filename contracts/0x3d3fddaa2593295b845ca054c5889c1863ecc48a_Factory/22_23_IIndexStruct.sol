//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IndexStruct {
    struct FeeData {
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
        bool distributeBeforePurchased;
    }

    struct Depositor {
        uint amount;
        bool status;
    }

    struct IndexData {
        string _reference;
        uint16[] _percentages;
        address[] _tokens;
        uint256 _depositendingtime;
        uint256 _indexendingtime;
        address _ptoken;
        uint256 _thresholdamount;
    }
}