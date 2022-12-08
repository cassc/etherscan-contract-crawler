// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface ISimpleUserProxy {
    function doCall(address _target, bytes calldata _data) external payable;
    function initialize(address _owner) external;
}