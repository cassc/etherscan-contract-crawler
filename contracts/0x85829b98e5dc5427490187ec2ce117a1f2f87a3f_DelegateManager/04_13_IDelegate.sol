// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import "./IOwnable.sol";

import "./ISimpleInitializable.sol";

import "./IWithdrawable.sol";

import "./IOwnershipManageable.sol";

// solhint-disable-next-line no-empty-blocks
interface IDelegate is ISimpleInitializable, IOwnable, IWithdrawable, IOwnershipManageable {

}