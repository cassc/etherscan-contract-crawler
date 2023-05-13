// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBananaAntiBot {
    function isBlacklisted(address account) external view returns (bool);

    function beforeTokenTransferCheck(address from, address to) external view returns (bool);
}