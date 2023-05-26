// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GOGOD is Ownable, ERC20, ERC20Burnable {
    constructor(   
    ) ERC20("GOD Fractions", "GODOG") {
        _mint(msg.sender, 6666000000*10**decimals());
        renounceOwnership();
    }

    // Receive function.
    receive() external payable {
        revert();
    }

    // Fallback function.
    fallback() external {
        revert();
    }
}