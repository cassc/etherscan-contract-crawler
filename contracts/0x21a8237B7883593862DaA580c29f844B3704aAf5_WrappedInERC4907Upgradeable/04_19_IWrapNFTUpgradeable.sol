// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IWrapNFTUpgradeable {

    function initialize(
        string memory name_,
        string memory symbol_,
        address originalAddress_,
        address operator
    )external;
}