// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdminWhitelistable {
    function updateAdminWhitelist(address _newAdminWhitelist) external;

    function isInWhitelist(address _address) external view returns (bool);
}