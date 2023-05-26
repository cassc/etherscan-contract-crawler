pragma solidity ^0.6.2;

import "./ERC20.sol";

contract Belega10 is ERC20 {
    constructor(uint256 initialSupply) ERC20("BELEGA", "BLGA") public {
        _setupDecimals(8);
        _mint(msg.sender, initialSupply * (10 ** uint256(decimals())));
    }
}