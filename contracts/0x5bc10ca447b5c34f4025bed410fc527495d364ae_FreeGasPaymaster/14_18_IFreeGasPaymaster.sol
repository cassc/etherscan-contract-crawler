// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./IPaymaster.sol";

interface IFreeGasPaymaster is IPaymaster {
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event Withdrawal(address indexed token, uint256 amount);
}