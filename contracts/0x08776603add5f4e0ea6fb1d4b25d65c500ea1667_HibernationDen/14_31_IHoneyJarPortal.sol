// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IHoneyJarPortal {
    function sendStartGame(
        address payable refundAddress_,
        uint256 destChainId_,
        uint8 bundleId_,
        uint256 numSleepers_,
        uint256[] calldata checkpoints_
    ) external payable;
    function sendFermentedJars(
        address payable refundAddress_,
        uint256 destChainId_,
        uint8 bundleId_,
        uint256[] calldata fermentedJarIds_
    ) external payable;
}