// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "ERC20.sol";

contract Tr4d is ERC20 {
    constructor() ERC20("TRAD", "TR4D") {
        _mint(msg.sender, 100000000 * 10 ** 18);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}