// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MUNCH is ERC20, Ownable {
    constructor() ERC20("MUNCH", "MUNCH") {
        _mint(msg.sender, 420_690_000_000 * 10 ** decimals());
    }
}