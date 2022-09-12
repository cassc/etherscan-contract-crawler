// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC165 {
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}