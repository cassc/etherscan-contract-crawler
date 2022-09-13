// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


abstract contract Wrappable {
    event UNWRAP(address indexed sender, string indexed BTCZrecipient, uint256 amount);
    event WRAP(string indexed BTCZsender, address indexed recipient, uint256 amount);
    constructor() {}
/*          INTERFACES            */
    // INTERNAL transfer from user to mintingAddress storing btcz recipient address
    function unwrap(string calldata BTCZrecipient, uint256 amount) external virtual returns (bool);
    
    // INTERNAL transfer from mintingAddress to user storing btcz sender address
    function wrap(string calldata BTCZsender, address recipient, uint256 amount) external virtual returns (bool);
}
