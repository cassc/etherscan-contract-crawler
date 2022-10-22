// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC165Admin {
    function setERC165(bytes4[] calldata interfaceIds, bytes4[] calldata interfaceIdsToRemove) external;
}