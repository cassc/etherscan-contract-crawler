// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

struct TargetInit {
    address admin;
    address manager;
    address minter;
    address creator;
    uint256 royaltyFee;
    uint16[] royaltySplits; // totaling 10000 (in BPS)
    address payable[] royaltyRecipients;
}

interface ITargetInitializer {
    function initialize(
        string memory name,
        string memory symbol,
        TargetInit calldata params,
        bytes memory data
    ) external;
}