// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IOwnable {
    function owner() external view returns (address);

    function admin() external view returns (address);

    function transferOwnership(address _newOwner) external returns (bool);

    function renounceOwnership() external returns (bool);
}