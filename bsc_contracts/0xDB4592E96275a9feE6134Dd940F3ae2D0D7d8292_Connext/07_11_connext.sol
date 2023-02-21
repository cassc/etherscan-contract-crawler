// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IConnextHandler {
    function xcall(
        uint32 destination,
        address recipient,
        address tokenAddress,
        address delegate,
        uint256 amount,
        uint256 slippage,
        bytes memory callData
    ) external payable returns (bytes32);
}