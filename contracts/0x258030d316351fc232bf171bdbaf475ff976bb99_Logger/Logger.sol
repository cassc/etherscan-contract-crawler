/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

contract Logger {
    event Log(string action, bytes data);

    function log(string calldata _action, bytes calldata _data) external {
        emit Log(_action, _data);
    }
}