// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "../../../Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MetaUnitFMIncentive is Pausable, ReentrancyGuard {
    mapping(address => bool) private _is_first_mint_resolved;
    address private _meta_unit_address;
    uint256 private _value;

    constructor(address owner_of_, address meta_unit_address_) Pausable(owner_of_) {
        _meta_unit_address = meta_unit_address_;
        _value = 4 ether;
    }

    function firstMint() public notPaused nonReentrant {
        require(!_is_first_mint_resolved[msg.sender], "You have already performed this action");
        IERC20(_meta_unit_address).transfer(msg.sender, _value);
        _is_first_mint_resolved[msg.sender] = true;
    }

    function isFirstMintResolved(address user_address) public view returns (bool) {
        return _is_first_mint_resolved[user_address];
    }

    function setValue(uint256 value_) public {
        require(msg.sender == _owner_of, "Permission denied");
        _value = value_;
    }

    function withdraw(uint256 amount_) public {
        require(msg.sender == _owner_of, "Permission denied");
        IERC20(_meta_unit_address).transfer(_owner_of, amount_);
    }

    function withdraw() public {
        require(msg.sender == _owner_of, "Permission denied");
        IERC20 metaunit = IERC20(_meta_unit_address);
        metaunit.transfer(_owner_of, metaunit.balanceOf(address(this)));
    }
}