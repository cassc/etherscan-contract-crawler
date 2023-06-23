// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IControllerLink {
    function addAuth(address _owner, address _account) external;

    function existing(address _account) external view returns (bool);
}