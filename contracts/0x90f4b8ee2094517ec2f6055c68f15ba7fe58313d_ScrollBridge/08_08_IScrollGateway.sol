// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IScrollGateway {
    function depositETHAndCall(
        address _to,
        uint256 _amount,
        bytes memory _data,
        uint256 _gasLimit
    ) external payable;
}