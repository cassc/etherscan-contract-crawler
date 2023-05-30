pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PrisonFI is ERC20 {
    constructor() ERC20("PrisonFI", "PrisonFI") {
        _mint(msg.sender, 100000000000 ether);
    }
}