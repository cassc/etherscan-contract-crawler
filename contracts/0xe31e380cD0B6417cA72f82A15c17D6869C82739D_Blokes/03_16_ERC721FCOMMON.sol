// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./ERC721F.sol";
import "./extensions/ERC721Payable.sol";

contract ERC721FCOMMON is ERC721F, ERC721Payable {
    constructor(string memory name_, string memory symbol_) ERC721F(name_, symbol_) {
    }
}