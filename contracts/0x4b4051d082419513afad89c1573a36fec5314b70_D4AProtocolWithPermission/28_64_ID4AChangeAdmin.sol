// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AChangeAdmin {
    function changeAdmin(address new_admin) external;
    function transferOwnership(address new_owner) external;
}