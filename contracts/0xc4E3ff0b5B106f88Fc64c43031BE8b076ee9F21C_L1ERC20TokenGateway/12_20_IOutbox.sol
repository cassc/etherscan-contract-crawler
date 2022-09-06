// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IOutbox {
    function l2ToL1Sender() external view returns (address);
}