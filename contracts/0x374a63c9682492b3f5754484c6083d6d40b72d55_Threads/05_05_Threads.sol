// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Threads is ERC20 {
    constructor() ERC20("THREADS", "Threads") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}