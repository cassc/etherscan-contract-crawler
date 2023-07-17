pragma solidity ^0.8.7;

interface IRNG_single_requestor {
    function process(uint256 rand, uint256 requestId) external;
}