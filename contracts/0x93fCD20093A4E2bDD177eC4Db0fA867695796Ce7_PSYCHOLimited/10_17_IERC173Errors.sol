// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IERC173Errors {
    error NonOwnership(address _owner, address _sender);

    error TransferOwnershipToZeroAddress(address _from, address _to);
}