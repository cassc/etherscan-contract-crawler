//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IGrantReceiver {
    function receiveGrant(
        address currency,
        uint256 amount,
        bytes calldata data
    ) external returns (bool result);
}