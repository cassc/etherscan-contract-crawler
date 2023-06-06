// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DFCHToken is ERC20 {
    constructor() ERC20("DeFi.ch", "DFCH") {
        _mint(_msgSender(), 1000000000 * (10**uint256(decimals())));
    }

    function burn(uint256 _amount) public {
        _burn(_msgSender(), _amount);
    }
}