// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface ICallProxy {
    function proxyCall(
        address ptoken,
        address receiver,
        uint256 amount,
        bytes memory callData
    ) external returns(bool);

    function encodeArgsForWithdraw(
        bytes memory ptokenAddress,
        bytes memory toAddress,
        uint256 amount
    ) external pure returns(bytes memory);
}