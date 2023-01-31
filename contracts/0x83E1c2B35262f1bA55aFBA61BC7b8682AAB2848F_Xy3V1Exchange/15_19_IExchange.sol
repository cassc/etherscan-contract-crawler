// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IExchange {
    function exchange(
        address sender,
        bytes memory _params
    ) external returns (bool, address, uint256);
}