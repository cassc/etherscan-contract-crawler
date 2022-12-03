// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;

interface IERC677Receiver {
    function onTokenTransfer(
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}