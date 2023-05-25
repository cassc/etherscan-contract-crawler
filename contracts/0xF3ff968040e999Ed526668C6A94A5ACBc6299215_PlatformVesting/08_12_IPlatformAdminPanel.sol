// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPlatformAdminPanel {
    function isAdmin(address wallet) external view returns (bool);
}