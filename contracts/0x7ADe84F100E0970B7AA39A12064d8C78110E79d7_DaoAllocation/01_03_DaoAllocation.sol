// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title DaoAllocation
 * @notice Contract which manages allocations in MetaPlayerOne.
 */
contract DaoAllocation is Pausable {
    struct Allocation { uint256 uid; address owner_of; address erc20address; uint256 amount; uint256 min_purchase; uint256 max_purchase; uint256 sold_amount; uint256 price; uint256 end_time; }
    struct Metadata { string name; string description; string file_uri;}
    
    Allocation[] private _allocations;

    /**
    * @dev setup owner of this contract.
    */
    constructor (address owner_of_) Pausable(owner_of_) {}

    /**
    * @dev emits when new allocation was created.
    */
    event allocationCreated(uint256 uid, address owner_of, address erc20address, uint256 amount, uint256 price, uint256 min_purchase, uint256 max_purchase, uint256 sold_amount, string wallpaper_uri, string description, string name, uint256 end_time);

    /**
    * @dev emits when someone claims allocation.
    */
    event claimed(uint256 allocation_uid, uint256 sold_amount, address eth_address);

    /**
    * @dev emits when creator of allocation withdraw allocation.
    */
    event withdrawed(uint256 allocation_uid, uint256 amount);

    /**
    * @dev function which creates allocation with params.
    * @param amount amount of ERC20 tokens which you will stake for allocation.
    * @param erc20address token address of ERC20 which you will stake for allocation.
    * @param min_purchase upper limit for claiming for every user.
    * @param max_purchase upper limit for claiming for every user.
    * @param price upper limit for claiming for every user.
    * @param period time in UNIX format which means how long should allocation runs.
    * @param metadata includes name of allocation, description and link to image
    */
    function createAllocation(uint256 amount, address erc20address, uint256 min_purchase, uint256 max_purchase, uint256 price, uint256 period, Metadata memory metadata) public notPaused {
        require(amount > min_purchase, "Min. purchase is greater than total amount");
        require(amount > max_purchase, "Max. purchase is greater than total amount");
        uint256 end_time = block.timestamp + period;
        uint256 newAllocationUid = _allocations.length;
        _allocations.push(Allocation(newAllocationUid, msg.sender, erc20address, amount, min_purchase, max_purchase, 0, price, end_time));
        IERC20(erc20address).transferFrom(msg.sender, address(this), amount);
        emit allocationCreated(newAllocationUid, msg.sender, erc20address, amount, price, min_purchase, max_purchase, 0, metadata.file_uri, metadata.description, metadata.name, end_time);
    }

    /**
    * @dev function which creates allocation with params.
    * @param allocation_uid unique id of allocation which you want claim.
    * @param amount amount of ERC20 tokens which you wan't to claim (should be less then "max_purchase" and greater than "min_purchase").
    */
    function claim(uint256 allocation_uid, uint256 amount) public payable notPaused {
        Allocation memory allocation = _allocations[allocation_uid];
        require(allocation.min_purchase <= amount, "Not enough tokens for buy");
        require(allocation.max_purchase >= amount, "Too much tokens for buy");
        require(block.timestamp < allocation.end_time, "Finished");
        require(allocation.sold_amount + amount <= allocation.amount, "Limit exeeded");
        require(msg.value >= (amount * allocation.price) / 1 ether, "Not enough funds send");
        IERC20(allocation.erc20address).transfer(msg.sender, amount * 977 / 1000);
        IERC20(allocation.erc20address).transfer(_owner_of, amount * 3 / 1000);
        _allocations[allocation_uid].sold_amount += amount;
        payable(_allocations[allocation_uid].owner_of).transfer(msg.value);
        emit claimed(allocation_uid, amount, msg.sender);
    }

    /**
    * @dev function which creates allocation with params.
    * @param allocation_uid unique id of allocation which you want claim.
    */
    function withdraw(uint256 allocation_uid) public notPaused {
        Allocation memory allocation = _allocations[allocation_uid];
        require(msg.sender == allocation.owner_of, "No permission");
        require(allocation.end_time < block.timestamp, "Not Finished");
        uint256 amount = allocation.amount - allocation.sold_amount;
        _allocations[allocation_uid].sold_amount = allocation.amount;
        IERC20(allocation.erc20address).transfer(msg.sender, amount);
        emit withdrawed(allocation_uid, amount);
    }
}