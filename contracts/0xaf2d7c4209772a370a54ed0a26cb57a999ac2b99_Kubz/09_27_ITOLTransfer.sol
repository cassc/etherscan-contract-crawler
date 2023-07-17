// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ITOLTransfer {
    function canDoKeepTOLTransfer(address from, address to) external view returns (bool);

    function beforeKeepTOLTransfer(address from, address to) external;
}