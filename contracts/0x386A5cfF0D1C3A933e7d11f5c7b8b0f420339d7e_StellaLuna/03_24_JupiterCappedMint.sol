// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JupiterNFT.sol';

abstract contract JupiterCappedMint is JupiterNFT {
    uint256  public cap;

    constructor () {
        cap = 7777;
    }

    function setCap(uint256 _cap) public  {
        require(operators[msg.sender], "only operators");
        cap = _cap;
    }

}