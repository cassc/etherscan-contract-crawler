// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ForceToken is ERC20 {
    constructor() ERC20("ethforce.xyz", "FORCE") {
        _mint(msg.sender, 42_111_222_333 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function theForce() public pure returns (string memory) {
        return "be with you!";
    }
}