// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

interface IWSProxy {
    function initialize(address _implementation, address _admin, bytes calldata _data) external;
    function upgradeTo(address _proxy) external;
    function upgradeToAndCall(address _proxy, bytes calldata data) external payable;
    function changeAdmin(address newAdmin) external;
    function admin() external returns (address);
    function implementation() external returns (address);
}