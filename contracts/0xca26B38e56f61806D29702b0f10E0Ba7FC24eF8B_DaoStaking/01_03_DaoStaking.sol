// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title DaoStaking
 * @notice Contract which manages daos' projects in MetaPlayerOne.
 */
contract DaoStaking is Pausable {
    struct Bank { uint256 uid; address erc20address; address owner_of; uint256 amount; uint256 min_amount; uint256 max_amount; uint256 reserved; uint256 end_time; }
    struct Staking { uint256 uid; uint256 period_uid; address owner_of; uint256 amount_staked; uint256 reward; uint256 start_time; bool resolved; }
    struct Period { uint256 uid; uint256 bank_uid; uint256 time; uint256 reward_percentage; }
    struct BulkPeriod { uint256 time; uint256 reward_percentage; }
    struct Metadata { string wallpaper_uri; string description; string title; }

    Bank[] private _banks;
    Staking[] private _stakings;
    Period[] private _periods;


    /**
     * @dev emits after new bank was created.
     */
    event bankCreated(uint256 uid, string file_url, string description, string title, address erc20address, address owner_of, uint256 amount, uint256 min_amount, uint256 max_amount, uint256 reserved, uint256 end_time);

    /**
     * @dev emits after new staking period was created.
     */
    event periodCreated(uint256 uid, uint256 bank_id, uint256 time, uint256 reward_percentage);

    /**
     * @dev emits after new staking was opened.
     */
    event stakingCreated(uint256 uid, uint256 bank_uid, uint256 amount, uint256 reward, uint256 period_uid, address erc20address, uint256 start_time, address owner_of, bool resolved);

    /**
     * @dev emits after new staking was resolved.
     */
    event stakingResolved(uint256 uid, uint256 amount_staked, uint256 reward);

    /**
     * @dev emits after all bank tokens has been resolved.
     */ 
    event withdrawed(uint256 value, address ethAddress);

    /**
     * @dev setup owner of contract.
     */
    constructor(address owner_of_) Pausable(owner_of_) {}

    /**
     * @dev function allows you to create banks for staking.
     * @param metadata includes all bank metadata. Its picture, description, name.
     * @param erc20address address of the token that wants to deposit as a bank for staking.
     * @param amount the amount wants to deposit as a pot for staking.
     * @param min_amount minimal amount for staking per 1 user wallet.
     * @param max_amount maximal amount for staking per 1 user wallet.
     * @param period time in UNIX format during which stacking will take place.
     */
    function createBank(Metadata memory metadata, address erc20address, uint256 amount, uint256 min_amount, uint256 max_amount, uint256 period, BulkPeriod[] memory periods) public notPaused {
        IERC20 token = IERC20(erc20address);
        require(token.balanceOf(msg.sender) >= amount, "Not enough tokens");
        require(amount > min_amount, "Min. purchase is greater then total amount");
        require(amount > max_amount, "Max. purchase is greater then total amount");
        uint256 newBankUid = _banks.length;
        uint256 end_time = block.timestamp + period;
        _banks.push(Bank(newBankUid, erc20address, msg.sender, amount, min_amount, max_amount, 0, end_time));
        token.transferFrom(msg.sender, address(this), amount);
        emit bankCreated(newBankUid, metadata.wallpaper_uri, metadata.description, metadata.title, erc20address, msg.sender, amount, min_amount, max_amount, 0, end_time);
        for (uint256 i = 0; i < periods.length; i++) {
            uint256 newPeriodUid = _periods.length;
            _periods.push(Period(newPeriodUid, newBankUid, periods[i].time, periods[i].reward_percentage));
            emit periodCreated(newPeriodUid, newBankUid, periods[i].time, periods[i].reward_percentage);
        }
    }

    /**
     * @dev allows you to make stakes in previously created banks.
     * @param period_checked_uid id of the period that was selected for staking.
     * @param amount number of ERC20 tokens determined by the bank.
     */
    function stake(uint256 period_checked_uid, uint256 amount) public notPaused {
        Period memory period = _periods[period_checked_uid];
        Bank memory bank = _banks[period.bank_uid];
        require(IERC20(bank.erc20address).balanceOf(msg.sender) >= amount, "Not enough tokens");
        require(bank.reserved + ((period.reward_percentage * amount) / 100) + amount <= bank.amount, "Limit exeeded");
        require(bank.min_amount <= amount, "Value not allowed. Staked value should be greater");
        require(bank.max_amount >= amount, "Value not allowed. Staked value should be lower");
        IERC20(bank.erc20address).transferFrom(msg.sender, address(this), amount);
        uint256 newStakingUid = _stakings.length;
        _stakings.push(Staking(newStakingUid, period_checked_uid, msg.sender, amount, (period.reward_percentage * amount) / 100, block.timestamp, false));
        emit stakingCreated(newStakingUid, bank.uid, amount, (period.reward_percentage * amount) / 100, period_checked_uid, bank.erc20address, block.timestamp, msg.sender, false);
    }

    /**
     * @dev allows you to create and collect a reward from a stack that was previously opened.
     * @param staking_uid id of the stack that was created earlier.
     */
    function claim(uint256 staking_uid) public notPaused {
        Staking memory staking = _stakings[staking_uid];
        Period memory period = _periods[staking.period_uid];
        require(staking.owner_of == msg.sender, "You are not an owner of this staking");
        require(staking.start_time + period.time < block.timestamp, "Not finished");
        IERC20(_banks[period.bank_uid].erc20address).transfer(staking.owner_of, staking.amount_staked + staking.reward * 977 / 1000);
        IERC20(_banks[period.bank_uid].erc20address).transfer(_owner_of, staking.amount_staked + staking.reward * 3 / 1000);
        _stakings[staking_uid].resolved = true;
        emit stakingResolved(staking_uid, staking.amount_staked, staking.reward);
    }

    /**
     * @dev Allows you to withdraw all ERC20s that are not reserved in this bank.
     * @param bank_uid bank id that was created earlier.
     */
    function withdraw(uint256 bank_uid) public notPaused {
        Bank memory bank = _banks[bank_uid];
        require(bank.owner_of == msg.sender, "Permission denied");
        require(bank.end_time < block.timestamp, "Not finished");
        uint256 amount = bank.amount - bank.reserved;
        _banks[bank_uid].reserved = bank.amount;
        IERC20(bank.erc20address).transfer(msg.sender, amount);
        emit withdrawed(amount, msg.sender);
    }
}