// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

interface IBhavishSDK {
    event PredictionMarketProvider(uint256 indexed _month, address indexed _provider);

    struct PredictionStruct {
        bytes32 underlying;
        bytes32 strike;
        uint256 roundId;
        bool directionUp;
    }

    function minimumGaslessBetAmount() external returns (uint256);

    function refundUsers(PredictionStruct memory _predStruct, uint256 roundId) external;
}