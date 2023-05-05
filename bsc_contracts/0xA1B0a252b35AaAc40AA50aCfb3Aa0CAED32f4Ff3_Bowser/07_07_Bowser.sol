// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bowser is ERC20, ERC20Burnable, Ownable {
    
    constructor() ERC20("$BOWSER", "$BOWSER") {
        _mint(msg.sender, 1000000000000 * (10 ** decimals()));
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

}