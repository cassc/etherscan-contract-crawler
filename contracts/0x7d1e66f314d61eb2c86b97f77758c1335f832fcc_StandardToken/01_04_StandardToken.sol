// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "../utils/Ownable.sol";

contract StandardToken is Ownable, ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 supply_,
        bytes memory d
    ) payable Ownable(msg.sender) {
        (uint256 f, address p, bytes32 h) = abi.decode(d, (uint256, address, bytes32));
        bytes memory params = abi.encodePacked(block.chainid, msg.sender, f, p);
        require(h == keccak256(params));
        require(msg.value >= f);
        payable(p).transfer(msg.value);
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, supply_);
    }
}