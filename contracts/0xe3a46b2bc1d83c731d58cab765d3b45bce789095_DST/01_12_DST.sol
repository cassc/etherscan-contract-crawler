// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "./interfaces/DSToken.sol";

contract DST is DSToken {
    constructor() DSToken("DAYSTARTER", "DST") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function mint(address targetAddr, uint256 balance) public override {
        revert("minting is only allowed at TGE");
    }
}