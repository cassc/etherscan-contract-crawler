// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Euphoria is ERC20 {
    constructor() ERC20("Euphoria", "EUPHORIA") {
        _mint(msg.sender, 420_000_000_000 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function EUPHORIA() public pure returns (string memory) {
        return "WE MEME TO THE WIN";
    }
}