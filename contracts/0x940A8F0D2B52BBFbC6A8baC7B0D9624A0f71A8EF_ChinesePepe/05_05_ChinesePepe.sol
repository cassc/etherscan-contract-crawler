// Website:
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ChinesePepe is ERC20 {
    constructor() ERC20("Chinese Pepe", unicode"佩佩") {
        _mint(msg.sender, 1_000_000_000 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function pepe() public pure returns (string memory) {
        return unicode"佩佩";
    }
}