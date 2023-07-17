// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.16;

interface IStargateReceiver {
    function sgReceive(
        uint16 chainId,
        bytes memory srcAddress,
        uint256 nonce,
        address token,
        uint256 amountLD,
        bytes memory payload
    ) payable external;
}