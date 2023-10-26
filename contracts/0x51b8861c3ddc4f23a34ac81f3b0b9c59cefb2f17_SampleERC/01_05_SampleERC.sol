// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SampleERC is ERC20 {

    // Override decimals() function to return 6
    
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    constructor() ERC20("CUTKITTS", "CUT") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}