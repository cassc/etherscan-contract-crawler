// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Nene is ERC20, Ownable {

    constructor() ERC20("Nene", "nene") {
        _mint(msg.sender, 999999999999999 * 10 ** decimals());
    }

    function twitter() external pure returns (string memory) {
        return "https://twitter.com/nenetoken";
    }
}