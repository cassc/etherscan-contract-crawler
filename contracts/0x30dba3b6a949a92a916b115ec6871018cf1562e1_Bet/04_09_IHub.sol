// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHub {
    function emitTopiaClaimed(address owner, uint256 amount) external;
}