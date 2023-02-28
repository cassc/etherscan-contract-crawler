/**
 *Submitted for verification at BscScan.com on 2023-02-07
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface TOKEN {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract PRESALE {
    address owner;
    address client = 0x684fC455EC45C49f9C93182b60C10Daa04e1FC35;
    uint256 priceRate;

    constructor() {
        priceRate = 500;
    }

    function Buy(uint256 busdAmount) public returns (bool) {
        TOKEN BUSD = TOKEN(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee);
        TOKEN LINGO = TOKEN(0x578386D25c1Ca3Fb5A1E0e60E11A12bFFe3219a6);
        BUSD.transferFrom(msg.sender, client, busdAmount * 1000000000);
        LINGO.transferFrom(owner, msg.sender, busdAmount * priceRate);
        return true;
    }

    function setRate(uint256 newRate) public {
        require(msg.sender == owner);
        priceRate = newRate;
    }

    function transferOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
}