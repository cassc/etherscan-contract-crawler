// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFomo {
    function onTransfer(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _transferType
    ) external;
}