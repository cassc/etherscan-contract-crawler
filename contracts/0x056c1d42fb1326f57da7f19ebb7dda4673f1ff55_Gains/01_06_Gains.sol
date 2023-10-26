pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Gains is ERC20Burnable {

    constructor() ERC20("GAINS", "GAINS") {
        _mint(msg.sender, 10**8 * 10 ** decimals());
    }
    
}