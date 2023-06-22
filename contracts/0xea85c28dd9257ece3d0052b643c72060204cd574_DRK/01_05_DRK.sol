pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DRK is ERC20 {
    constructor() public ERC20("DRK", "DRK") {
        _mint(msg.sender, 2100000000000000000000000000);
    }
}