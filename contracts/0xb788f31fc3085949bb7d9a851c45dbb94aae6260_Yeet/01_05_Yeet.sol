// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Yeet is ERC20 {
    constructor() ERC20("Yeet", "YEET") {
        _mint(msg.sender, 420690333123 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function yeet() public pure returns (string memory) {
        return "yeeeeeeeeeeet";
    }
}