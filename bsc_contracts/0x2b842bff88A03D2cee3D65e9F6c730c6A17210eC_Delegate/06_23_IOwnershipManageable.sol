// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IOwnershipManageable {
    function setOwner(address newOwner) external;
}