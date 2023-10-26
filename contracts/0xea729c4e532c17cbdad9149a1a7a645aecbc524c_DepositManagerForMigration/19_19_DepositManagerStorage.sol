// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract DepositManagerStorage   {
    ////////////////////
    // Storage - contracts
    ////////////////////

    address internal _wton;
    address internal _registry;
    address internal _seigManager;
    address public oldDepositManager;

    ////////////////////
    // Storage - token amount
    ////////////////////

    // accumulated staked amount
    // layer2 => msg.sender => wton amount
    mapping (address => mapping (address => uint256)) internal _accStaked;
    // layer2 => wton amount
    mapping (address => uint256) internal _accStakedLayer2;
    // msg.sender => wton amount
    mapping (address => uint256) internal _accStakedAccount;

    // pending unstaked amount
    // layer2 => msg.sender => wton amount
    mapping (address => mapping (address => uint256)) internal _pendingUnstaked;
    // layer2 => wton amount
    mapping (address => uint256) internal _pendingUnstakedLayer2;
    // msg.sender => wton amount
    mapping (address => uint256) internal _pendingUnstakedAccount;

    // accumulated unstaked amount
    // layer2 => msg.sender => wton amount
    mapping (address => mapping (address => uint256)) internal _accUnstaked;
    // layer2 => wton amount
    mapping (address => uint256) internal _accUnstakedLayer2;
    // msg.sender => wton amount
    mapping (address => uint256) internal _accUnstakedAccount;

    // layer2 => msg.sender => withdrawal requests
    mapping (address => mapping (address => WithdrawalReqeust[])) internal _withdrawalRequests;

    // layer2 => msg.sender => index
    mapping (address => mapping (address => uint256)) internal _withdrawalRequestIndex;

    ////////////////////
    // Storage - configuration / ERC165 interfaces
    ////////////////////

    // withdrawal delay in block number
    // @TODO: change delay unit to CYCLE?
    uint256 public globalWithdrawalDelay;
    mapping (address => uint256) public withdrawalDelay;

    struct WithdrawalReqeust {
        uint128 withdrawableBlockNumber;
        uint128 amount;
        bool processed;
    }
}