// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IVRFv2Consumer {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    function requestRandomWords() external returns (uint256 requestId);

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords);
}