// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721Creator} from "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";

contract RedBullCreator is ERC721Creator {
    constructor(string memory name_, string memory symbol_) ERC721Creator(name_, symbol_) {}
}