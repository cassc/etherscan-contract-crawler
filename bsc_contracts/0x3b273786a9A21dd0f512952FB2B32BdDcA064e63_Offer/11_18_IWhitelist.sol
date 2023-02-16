// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWhitelist {
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function GRANT_ROLE() external view returns (bytes32);

    function ADMIN_ROLE() external view returns (bytes32);

}