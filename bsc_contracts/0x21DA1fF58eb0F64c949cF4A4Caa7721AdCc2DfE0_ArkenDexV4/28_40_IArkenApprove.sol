// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IArkenApprove {
    function transferToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;

    function updateCallableAddress(address _callableAddress) external;
}