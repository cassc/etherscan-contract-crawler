// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MetaUnitAllocation
 * @notice Manages token distribution to investors 
 */
contract MetaUnitAllocation is Pausable {
    struct Staking { address eth_address; uint256 amount; }

    address private _meta_unit_address;

    mapping(address => bool) private _white_list_addresses;
    mapping(address => uint256) private _staking_amounts;
    mapping(address => uint256) private _staking_intervals;
    mapping(address => uint256) private _staking_counters;

    /**
    * @dev setup MetaUnit address and owner of this contract
    */
    constructor(address meta_unit_address_, address owner_of_) Pausable(owner_of_) {
        _meta_unit_address = meta_unit_address_;
    }

    /**
    * @dev function allows you to add new user addresses to the white list
    * @param addresses list of funds addresses and thier parts of MetaUnit
    * @param setter boolean value of action
    */
    function setWhiteList(Staking[] memory addresses, bool setter) public {
        require(_owner_of == msg.sender, "Permission address");
        for (uint256 i = 0; i < addresses.length; i++) {
            _white_list_addresses[addresses[i].eth_address] = setter;
            _staking_amounts[addresses[i].eth_address] = addresses[i].amount;
        }
    }

    /**
    * @dev function allows claiming of metaunits under established conditions
    */
    function claim() public notPaused {
        require(_white_list_addresses[msg.sender], "You are not in white list");
        require(_staking_intervals[msg.sender] + 30 days <= block.timestamp, "Intervals between claiming should be 30 days");
        require(_staking_counters[msg.sender] < 13, "You can claim metaunit only 12 times");
        if (_staking_counters[msg.sender] < 12) {
            IERC20(_meta_unit_address).transfer(msg.sender, _staking_amounts[msg.sender] / 100);
        } else {
            IERC20(_meta_unit_address).transfer(msg.sender, _staking_amounts[msg.sender]);
        }
        _staking_intervals[msg.sender] = block.timestamp;
        _staking_counters[msg.sender] += 1;
    }
    
    /**
    * @dev function allows withdrawing all MetaUnit from current contract to owner
    */
    function withdraw() public {
        require(_owner_of == msg.sender, "Permission address");
        IERC20 token = IERC20(_meta_unit_address);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}