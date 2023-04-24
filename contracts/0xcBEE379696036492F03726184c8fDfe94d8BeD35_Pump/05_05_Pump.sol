pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Pump is ERC20 {
    constructor() ERC20("Pump", "PUMP") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }
}