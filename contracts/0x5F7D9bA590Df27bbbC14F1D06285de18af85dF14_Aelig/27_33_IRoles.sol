// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRoles {

    function setAdmin(address account) external;
    function revokeAdmin(address account) external;
    function renounceAdmin() external;
    function updateManager(address account) external;
    function isAccountAdmin(address account) external view returns(bool);
}