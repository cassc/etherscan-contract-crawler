// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FayreToken is ERC20Burnable, Ownable {
    constructor(address recipient) ERC20("Fayre", "FAYRE")  {        
        _mint(recipient, 1_000_000_000e18);
    }

    function getOwner() external view returns (address) {
        return owner();
    }
}