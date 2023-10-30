// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Base1155} from "./tokens/Base1155.sol";

contract Machines is Base1155 {
    constructor(uint96 _royalty, string memory _name, string memory _symbol) Base1155(_royalty, _name, _symbol) {}
}