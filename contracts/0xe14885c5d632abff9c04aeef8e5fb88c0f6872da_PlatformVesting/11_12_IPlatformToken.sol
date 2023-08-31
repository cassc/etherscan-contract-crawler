// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPlatformToken {
    function specialTransferFrom(
        address from,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}