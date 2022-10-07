// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title DaoAirdrop
 * @notice Contract which manages airdrops in MetaPlayerOne.
 */
contract DaoAirdrop is Pausable {
    struct Airdrop { uint256 uid; address owner_of; address erc20address; uint256 amount; uint256 max_per_user; uint256 start_time; uint256 period; uint256 droped_amount; }
    struct Metadata { string name; string description; string file_uri; }

    Airdrop[] private _airdrops;
    
    mapping(uint256 => mapping(address => uint256)) private _airdrop_limit;

    /**
    * @dev setup owner of this contract.
    */
    constructor (address owner_of_) Pausable(owner_of_) {}

    /**
    * @dev emits when new airdrop was created.
    */
    event airdropCreated(uint256 uid, address owner_of, address erc20address, uint256 amount, uint256 max_per_user, uint256 start_time, uint256 period, uint256 end_time, string file_uri, string description, string name, uint256 droped_amount);

    /**
    * @dev emits when someone claims airdrop.
    */
    event claimed(uint256 airdrop_uid, uint256 sold_amount, address eth_address);

    /**
    * @dev emits when creator of airdrop withdraw airdrop.
    */
    event withdrawed(uint256 airdrop_uid, uint256 amount);

    /**
    * @dev function which creates airdrop with params.
    * @param amount amount of ERC20 tokens which you will stake for airdrop.
    * @param erc20address token address of ERC20 which you will stake for airdrop.
    * @param max_per_user upper limit for claiming for every user.
    * @param start_time time in UNIX format when airdrop should start.
    * @param period time in UNIX format which means how long should airdrop runs.
    * @param metadata includes name of airdrop, description and link to image.
    */
    function createAirdrop(uint256 amount, address erc20address, uint256 max_per_user, uint256 start_time, uint256 period, Metadata memory metadata) public notPaused {
        require(amount > max_per_user, "Max. limit per wallet is greater than total amount");
        uint256 newAirdropUid = _airdrops.length;
        _airdrops.push(Airdrop(newAirdropUid, msg.sender, erc20address, amount, max_per_user, start_time, period, 0));
        IERC20(erc20address).transferFrom(msg.sender, address(this), amount);
        emit airdropCreated(newAirdropUid, msg.sender, erc20address, amount, max_per_user, start_time, period, start_time + period, metadata.file_uri, metadata.description, metadata.name, 0);
    }

    /**
    * @dev function which creates airdrop with params.
    * @param airdrop_uid unique id of airdrop which you want claim.
    * @param amount amount of ERC20 tokens which you wan't to claim (should be less then "max_per_user").
    */
    function claim(uint256 airdrop_uid, uint256 amount) public notPaused {
        Airdrop memory airdrop = _airdrops[airdrop_uid];
        require(_airdrop_limit[airdrop_uid][msg.sender] + amount <= airdrop.max_per_user, "Limit per user exeeded");
        require(airdrop.droped_amount + amount <= airdrop.amount, "Drop limit exeeded");
        require(airdrop.start_time <= block.timestamp, "Aidrop not started");
        require(airdrop.start_time + airdrop.period >= block.timestamp, "Aidrop has been finished");
        IERC20(airdrop.erc20address).transfer(msg.sender, amount * 977 / 1000);
        IERC20(airdrop.erc20address).transfer(_owner_of, amount * 3 / 1000);
        _airdrops[airdrop_uid].droped_amount += amount;
        _airdrop_limit[airdrop_uid][msg.sender] += amount;
        emit claimed(airdrop_uid, amount, msg.sender);
    }

    /**
    * @dev function which creates airdrop with params.
    * @param airdrop_uid unique id of airdrop which you want claim.
    */
    function withdraw(uint256 airdrop_uid) public notPaused {
        Airdrop memory aidrop = _airdrops[airdrop_uid];
        require(msg.sender == aidrop.owner_of, "No permission");
        require(aidrop.start_time + aidrop.period < block.timestamp, "Not Finished");
        uint256 amount = aidrop.amount - aidrop.droped_amount;
        _airdrops[airdrop_uid].droped_amount = aidrop.amount;
        IERC20(aidrop.erc20address).transfer(msg.sender, amount);
        emit withdrawed(airdrop_uid, amount);
    }
}