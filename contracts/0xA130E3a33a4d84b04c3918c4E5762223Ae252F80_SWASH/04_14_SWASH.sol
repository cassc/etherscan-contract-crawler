// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./ERC677.sol";
import "./IERC677Receiver.sol";

contract SWASH is ERC677, ERC20Permit, ERC20Burnable {

    constructor() ERC20("Swash Token", "SWASH") ERC20Permit("SWASH") {
        _mint(msg.sender, 10**27);
    }
}