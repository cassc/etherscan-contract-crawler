pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract BETRA is ERC20, ERC20Detailed {
    constructor(uint256 initialSupply) ERC20Detailed("Betra coin", "BETRA", 18) public {
        _mint(msg.sender, initialSupply);
    }
}