// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {Withdraw} from "../withdraw/IWithdrawable.sol";

import {IDelegateDeployer} from "./IDelegateDeployer.sol";

interface IDelegateManager is IDelegateDeployer {
    function withdraw(address account, Withdraw[] calldata withdraws) external;
}