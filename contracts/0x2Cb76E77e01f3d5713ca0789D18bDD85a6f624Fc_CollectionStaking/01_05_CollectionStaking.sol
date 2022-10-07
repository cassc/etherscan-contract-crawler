// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title CollectionStaking
 */

contract CollectionStaking is Pausable {
    struct Bank { uint256 uid; address erc20address; uint256 reserved; uint256 amount; address erc721address; uint256 min_per_staking; uint256 max_per_staking; address owner_of; }
    struct Period { uint256 uid; uint256 bank_uid; uint256 time; uint256 reward; }
    struct BulkPeriod { uint256 time; uint256 reward; }
    struct Staking { uint256 uid; uint256 period_uid; address owner_of; uint256 start_time; bool closed; }
    struct Metadata { string file_uri; string title; string description; }

    mapping(address => mapping(uint256 => uint256[])) private _staked_tokens;

    Bank[] private _banks;
    Staking[] private _stakings;
    Period[] private _periods;

    constructor(address owner_of_) Pausable(_owner_of) {}
    
    event bankCreated(uint256 uid, string file_url, string title, string description, address erc20address, uint256 amount, address erc721address, uint256 min_per_user, uint256 max_per_user, address owner_of);
    event periodCreated(uint256 uid, uint256 bank_uid, uint256 time, uint256 reward);
    event stakingCreated(uint256 uid, uint256 bank_uid, uint256 period_uid, address erc721address, uint256 start_time, address owner_of, bool closed);
    event tokensAdded(address owner_of, uint256 staking_uid, uint256 bank_uid, uint256[] token_ids, address erc721address, uint256 period_uid);
    event claimed(uint256 staking_uid, uint256 bank_uid, address owner_of, uint256 amount);
    event withdrawed(address owner_of, uint256 amount, uint256 bank_uid);

    function createBank(Metadata memory metadata, address erc20address, uint256 amount, address erc721address, uint256 min_per_user, uint256 max_per_user, BulkPeriod[] memory periods) public {
        uint256 newBankId = _banks.length;
        _banks.push(Bank(newBankId, erc20address, 0, amount, erc721address, min_per_user, max_per_user, msg.sender));
        emit bankCreated(newBankId, metadata.file_uri, metadata.title, metadata.description, erc20address, amount, erc721address, min_per_user, max_per_user, msg.sender);
        IERC20(erc20address).transferFrom(msg.sender, address(this), amount);
        for (uint256 i = 0; i < periods.length; i++) {
            uint256 newPeriodId = _periods.length;
            _periods.push(Period(newPeriodId, newBankId, periods[i].time, periods[i].reward));
            emit periodCreated(newPeriodId, newBankId, periods[i].time, periods[i].reward);
        }
    }

    function stake(address erc721address, uint256[] memory token_ids, uint256 period_checked_uid) public {
        IERC721 token = IERC721(erc721address);
        for (uint256 i = 0; i < token_ids.length; i++) {
            require(token.ownerOf(token_ids[i]) == msg.sender, "You are not an owner of token");
        }
        Period memory period = _periods[period_checked_uid];
        Bank memory bank = _banks[period.bank_uid];
        require(token_ids.length >= bank.min_per_staking, "No such tokens for staking");
        require(token_ids.length <= bank.max_per_staking, "Too much tokens for staking");
        require((token_ids.length * period.reward) + bank.reserved <= bank.amount, "Not enough tokens in bank for staking");
        require(bank.erc721address == erc721address, "Period is not available");
        for (uint256 i = 0; i < token_ids.length; i++) {
            token.transferFrom(msg.sender, address(this), token_ids[i]);
        }
        uint256 newStakingId = _stakings.length;
        _stakings.push(Staking(newStakingId, period_checked_uid, msg.sender, block.timestamp, false));
        emit stakingCreated(newStakingId, period.bank_uid, period_checked_uid, erc721address, block.timestamp, msg.sender, false);
        _staked_tokens[msg.sender][newStakingId] = token_ids;
        emit tokensAdded(msg.sender, newStakingId, period.bank_uid, token_ids, erc721address, period_checked_uid);
        _banks[period.bank_uid].reserved += token_ids.length * period.reward;
    }

    function claim(uint256 staking_uid) public {
        Staking memory staking = _stakings[staking_uid];
        require(staking.owner_of == msg.sender, "Permission denied! Not your staking");
        Period memory period = _periods[staking.period_uid];
        require(staking.start_time + period.time <= block.timestamp, "Staking does not finished");
        require(!staking.closed, "Staking has been resolved");
        Bank memory bank = _banks[period.bank_uid];
        for (uint256 i = 0; i < _staked_tokens[msg.sender][staking_uid].length; i++) {
            IERC721(bank.erc721address).transferFrom(address(this), staking.owner_of, _staked_tokens[staking.owner_of][staking_uid][i]);
        }
        emit claimed(staking_uid, bank.uid, staking.owner_of, period.reward * _staked_tokens[msg.sender][staking_uid].length);
        IERC20(bank.erc20address).transfer(staking.owner_of, period.reward * _staked_tokens[msg.sender][staking_uid].length);
        _stakings[staking_uid].closed = true;
    }

    function withdraw(uint256 bank_uid) public {
        Bank memory bank = _banks[bank_uid];
        require(msg.sender == bank.owner_of, "You are not an owner");
        require(bank.amount - bank.reserved > 0, "Nothing to withdraw");
        IERC20(bank.erc20address).transfer(msg.sender, bank.amount - bank.reserved);
        emit withdrawed(msg.sender, bank.amount - bank.reserved, bank_uid);
    }
}