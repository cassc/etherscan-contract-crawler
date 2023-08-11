// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/credit-cooperative/Line-Of-Credit/blob/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

interface ILineFactory {
    struct CoreLineParams {
        address borrower;
        uint256 ttl;
        uint32 cratio;
        uint8 revenueSplit;
    }

    event DeployedSecuredLine(
        address indexed deployedAt,
        address indexed escrow,
        address indexed spigot,
        address swapTarget,
        uint8 revenueSplit
    );

    event RegisteredSecuredLine(
        address indexed deployedAt,
        address indexed escrow,
        address indexed spigot,
        address swapTarget,
        uint8 revenueSplit
    );

    event RegisteredUpdatedStatus(address indexed line, uint256 indexed status); // store as normal uint so it can be indexed in subgraph

    event RegisteredLine(address indexed line, address indexed oracle, address indexed arbiter, address borrower, address operator);


    error ModuleTransferFailed(address line, address spigot, address escrow);
    error InvalidRevenueSplit();
    error InvalidOracleAddress();
    error InvalidSwapTargetAddress();
    error InvalidArbiterAddress();
    error InvalidEscrowAddress();
    error InvalidSpigotAddress();

    function deployEscrow(uint32 minCRatio, address owner, address borrower) external returns (address);

    function deploySpigot(address owner, address operator) external returns (address);

    function deploySecuredLine(address borrower, uint256 ttl) external returns (address);

    function deploySecuredLineWithConfig(CoreLineParams calldata coreParams) external returns (address);

    function deploySecuredLineWithModules(
        CoreLineParams calldata coreParams,
        address mSpigot,
        address mEscrow
    ) external returns (address);

    function rolloverSecuredLine(address payable oldLine, address borrower, uint256 ttl) external returns (address);
}