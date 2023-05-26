// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "contracts/GigaNFT.sol";

contract Experimental is GigaNFT {
    constructor(string memory name_, string memory symbol_, uint256 initialMint, string memory blindBoxTokenURI) GigaNFT(name_, symbol_, initialMint, blindBoxTokenURI) {}
}