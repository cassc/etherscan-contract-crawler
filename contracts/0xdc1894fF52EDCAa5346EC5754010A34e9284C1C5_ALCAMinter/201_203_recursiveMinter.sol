// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Minter {
    constructor(address payable addr) payable {
        uint256 gl = gasleft();
        while (gl > 801010) {
            FooToken(addr).mint{gas: 801010}(msg.sender);
            gl = gasleft();
        }
    }
}

contract FooToken is ERC20("foo", "f") {
    function mint(address to) public payable {
        _mint(to, 1);
    }
}