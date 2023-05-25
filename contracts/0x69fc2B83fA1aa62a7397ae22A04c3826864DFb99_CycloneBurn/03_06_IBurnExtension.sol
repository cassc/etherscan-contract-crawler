//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IBurnExtension {
    function airdrop(
        address creatorContractAddress,
        uint256 index,
        address[] calldata recipients,
        uint32[] calldata amounts
    ) external;
}