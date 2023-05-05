// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Scat is ERC20 {
    constructor() ERC20("scatcoin.xyz", unicode"💩") {
        _mint(msg.sender, 42_111_111_111 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function poo() public pure returns (string memory) {
        return unicode"💩";
    }
}