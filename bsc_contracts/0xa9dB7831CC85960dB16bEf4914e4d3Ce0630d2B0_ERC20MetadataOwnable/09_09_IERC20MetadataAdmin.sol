// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20MetadataAdmin {
    function setDecimals(uint8 newDecimals) external;

    function lockDecimals() external;
}