// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IOwnable} from "../../lib/IOwnable.sol";

import {ISimpleInitializable} from "../init/ISimpleInitializable.sol";

import {IWithdrawable} from "../withdraw/IWithdrawable.sol";

import {IOwnershipManageable} from "./IOwnershipManageable.sol";

// solhint-disable-next-line no-empty-blocks
interface IDelegate is ISimpleInitializable, IOwnable, IWithdrawable, IOwnershipManageable {

}