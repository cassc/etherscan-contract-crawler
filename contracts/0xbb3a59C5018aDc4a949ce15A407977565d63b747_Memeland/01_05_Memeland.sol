// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Memeland is ERC20 {

    constructor() ERC20("Memeland $MEME", "MEMELAND") {
        _mint(msg.sender, 420000000 ether);
    }

}