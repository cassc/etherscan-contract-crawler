// Website:
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract REEE is ERC20 {
    constructor() ERC20("reee.finance", "REEE") {
        _mint(msg.sender, 1_111_111_111 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function reee() public pure returns (string memory) {
        return "EEEEEEEEE";
    }
}