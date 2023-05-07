// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Gucci is ERC20 {
    constructor() ERC20("we gucci", "GUCCI") {
        _mint(msg.sender, 420000000000 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function gucci() public pure returns (string memory) {
        return "we gucci forever";
    }
}