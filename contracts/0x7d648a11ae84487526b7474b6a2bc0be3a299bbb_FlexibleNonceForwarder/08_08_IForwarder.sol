// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

pragma experimental ABIEncoderV2;

interface IForwarder {
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    function execute(
        ForwardRequest calldata req,
        bytes calldata signature
    ) external payable returns (bool, bytes memory);

    function getNonce(address from) external view returns (uint256);
}