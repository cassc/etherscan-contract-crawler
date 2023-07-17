pragma solidity ^0.8.7;

interface IRNG_multi_requestor {
    function multi_process(uint256[] memory randomWords, uint256 _requestId) external;
}