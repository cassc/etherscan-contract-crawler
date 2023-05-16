// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "ERC20.sol";

contract Booby is ERC20 {
    constructor() ERC20("Boobytrap", "BOOBY") {
        _mint(msg.sender, 100000000 * 10 ** 18);
    }

}