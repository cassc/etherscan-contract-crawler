pragma solidity ^0.6.0;

import "ERC20.sol";

contract Bluemel is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Bluemel", "BLUEMEL") {
        _mint(msg.sender, initialSupply);
    }
}