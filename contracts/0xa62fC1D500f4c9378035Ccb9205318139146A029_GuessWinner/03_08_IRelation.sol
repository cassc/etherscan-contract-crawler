// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRelation {
    function bind(address _account, address _referrer) external;

    function getUserSuperior(address account) external view returns (address);

    function getUserActive(address account) external view returns (bool);
}