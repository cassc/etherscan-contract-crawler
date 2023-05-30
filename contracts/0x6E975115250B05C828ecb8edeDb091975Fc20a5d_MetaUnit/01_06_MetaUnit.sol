// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MetaUnit
 * @notice MetaPlayerOne's ERC20 token
 */
contract MetaUnit is ERC20Burnable {
    /**
     * @dev establishes a contract owner and mints 10 billion of MetaUnit to contract owner.
     */
    constructor(address owner_of_) ERC20("MetaUnit", "MEU") {
        _mint(owner_of_, 10000000000 ether);
    }
}