// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

interface IDSProxy {
    function owner() external view returns (address);
    function setCache(address _cacheAddr) external payable returns (bool);
    function execute(address _target, bytes memory _data) external payable returns (bytes32);
}