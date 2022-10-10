// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.4;

library EDataTypes {
    enum EventStatus {
        AVAILABLE,
        PROGRESS,
        FINISH
    }

    struct Event {
        uint256 startTime;
        uint256 deadlineTime;
        uint256 endTime;
        uint256 resultIndex;
        EventStatus status;
        address helperAddress;
        address creator;
        uint256[] odds;
        string _datas;
        uint256 pro;
        bool isBlock;
        uint256 finalTime;
        uint256 claimTime;
        bool affiliate;
        uint256 hostFee;
    }

    struct Prediction {
        uint256 predictionAmount;
        uint256 predictOptions;
        bool claimed;
    }
}