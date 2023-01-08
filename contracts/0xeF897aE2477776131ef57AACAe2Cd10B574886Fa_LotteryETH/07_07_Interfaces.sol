// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

interface IVRFCoordinatorV2 {

    function addConsumer(
        uint64 subId,
        address consumer
    )
        external;

    function createSubscription()
        external
        returns (uint64 subId);

    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    )
        external
        returns (uint256 requestId);
}

interface ILinkToken {

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    )
        external
        returns (bool success);
}