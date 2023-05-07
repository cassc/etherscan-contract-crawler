// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Weed is ERC20 {
    constructor() ERC20("Weed", "WEED") {
        _mint(msg.sender, 100_000_000_000 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function weed() public pure returns (string memory) {
        return "smoke weed, buy shitcoins, thats life!";
    }
}