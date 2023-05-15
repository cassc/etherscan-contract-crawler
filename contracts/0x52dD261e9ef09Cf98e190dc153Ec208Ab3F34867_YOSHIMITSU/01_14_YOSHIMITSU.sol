// YOSHIMITSU WILL BE A REVOLUTIONARY IDOL WITH-IN THE CRYPTOSPHERE

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract YOSHIMITSU is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    constructor() ERC20("YOSHIMITSU", "YOSHIMITSU") ERC20Permit("YOSHIMITSU") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}