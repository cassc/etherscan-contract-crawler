pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    constructor() ERC20("MUSDT", "MUSDT") {
        _mint(msg.sender, 100000000e18);
    }
}