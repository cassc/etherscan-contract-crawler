// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6a5bbfc4cbd0208fd350ca69152c0b8d0a989e55/contracts/token/ERC20/ERC20.sol";


contract ScholeumToken is ERC20 {
    
    constructor() ERC20("Scholeum", "SCLM") {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }
}