// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IMultiModelNftUpgradeable {
    function doAirdrop(uint256 _modelId, address[] memory _accounts) external returns(uint256 leftCapacity);
}