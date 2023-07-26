// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface ITransferListener {
    function onTransfer(
        address operator,
        address src,
        address dst,
        uint256 amount
    ) external;
}