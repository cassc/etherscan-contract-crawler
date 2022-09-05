// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

/// @dev We need an interface to interact with legacy linked libraries
///      that we don't want to deploy again.
interface IDetail {
    function getItemNameById(uint8 id)
        external
        pure
        returns (string memory name);
}