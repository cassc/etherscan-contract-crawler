// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract CreditSuisseCollapse is ERC20 {

    uint initialSupply = 100 * 10**6;

    constructor() ERC20("Credit Suisse Collapse", "SUISSE") {
        _mint(msg.sender, initialSupply * 10**18);
    }
}